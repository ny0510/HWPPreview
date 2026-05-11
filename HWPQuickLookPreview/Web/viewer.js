import init, { HwpDocument } from './rhwp.js';

const viewer = document.getElementById('viewer');

const defaultZoom = 1;
const minZoom = 1;
const maxZoom = 3;
const wheelZoomSensitivity = 0.01;
const viewerHorizontalPadding = 0;
const viewerVerticalChrome = 0;

let wasmReady = null;
let canvasContext = null;
let lastMeasuredFont = '';
let currentZoom = defaultZoom;
let currentFitWidth = 320;
let gestureStartZoom = null;

window.addEventListener('error', (event) => {
  reportToHost('error', event.error || event.message || 'Unknown JavaScript error');
});

window.addEventListener('unhandledrejection', (event) => {
  reportToHost('error', event.reason || 'Unhandled JavaScript promise rejection');
});

window.addEventListener('resize', updateFitWidth);

viewer.addEventListener('wheel', handleWheel, { passive: false });
viewer.addEventListener('gesturestart', handleGestureStart, { passive: false });
viewer.addEventListener('gesturechange', handleGestureChange, { passive: false });
viewer.addEventListener('gestureend', handleGestureEnd, { passive: false });

applyZoom();
updateFitWidth();

globalThis.measureTextWidth = (font, text) => {
  if (!canvasContext) {
    canvasContext = document.createElement('canvas').getContext('2d');
  }

  if (font !== lastMeasuredFont) {
    canvasContext.font = font;
    lastMeasuredFont = font;
  }

  return canvasContext.measureText(text).width;
};

window.bootstrapRhwp = (payload) => {
  if (wasmReady) {
    return;
  }

  const wasmBytes = decodeBase64(payload.wasmBase64);
  wasmReady = init({ module_or_path: wasmBytes });

  wasmReady.catch((error) => {
    wasmReady = null;
    renderError(error);
  });
};

window.renderHWPPreview = async (payload) => {
  try {
    if (!wasmReady) {
      throw new Error('rhwp WASM has not been initialized.');
    }

    viewer.replaceChildren();
    resetZoom();

    await wasmReady;

    const bytes = decodeBase64(payload.base64);
    const hwpDocument = new HwpDocument(bytes);

    try {
      const pageCount = hwpDocument.pageCount();

      if (pageCount <= 0) {
        renderEmpty('표시할 페이지가 없습니다.');
        return;
      }

      const documentElement = document.createElement('div');
      documentElement.className = 'document';

      for (let pageIndex = 0; pageIndex < pageCount; pageIndex += 1) {
        const page = document.createElement('article');
        page.className = 'page';
        page.dataset.page = String(pageIndex + 1);
        page.innerHTML = hwpDocument.renderPageSvg(pageIndex);
        documentElement.appendChild(page);
      }

      viewer.replaceChildren(documentElement);
      reportDocumentSize(documentElement);
      updateFitWidth();
    } finally {
      hwpDocument.free();
    }
  } catch (error) {
    renderError(error);
  }
};

window.showHWPPreviewError = (payload) => {
  const message = payload && payload.message ? payload.message : String(payload);
  renderError(new Error(message));
};

function renderEmpty(message) {
  const element = document.createElement('section');
  element.className = 'empty';
  element.textContent = message;
  resetZoom();
  viewer.replaceChildren(element);
}

function renderError(error) {
  const element = document.createElement('section');
  element.className = 'error';
  element.textContent = error instanceof Error ? error.message : String(error);
  resetZoom();
  viewer.replaceChildren(element);
}

function resetZoom() {
  setZoom(defaultZoom, viewerCenterPoint());
}

function handleWheel(event) {
  if (!event.ctrlKey) {
    return;
  }

  event.preventDefault();
  const zoomFactor = Math.exp(-event.deltaY * wheelZoomSensitivity);
  setZoom(currentZoom * zoomFactor, pointInViewer(event));
}

function handleGestureStart(event) {
  event.preventDefault();
  gestureStartZoom = currentZoom;
}

function handleGestureChange(event) {
  event.preventDefault();

  if (!Number.isFinite(event.scale)) {
    return;
  }

  if (gestureStartZoom === null) {
    gestureStartZoom = currentZoom;
  }

  setZoom(gestureStartZoom * event.scale, pointInViewer(event));
}

function handleGestureEnd(event) {
  event.preventDefault();
  gestureStartZoom = null;
}

function setZoom(nextZoom, focalPoint) {
  if (!Number.isFinite(nextZoom)) {
    return;
  }

  const clampedZoom = Math.max(minZoom, Math.min(maxZoom, nextZoom));
  const previousZoom = currentZoom;
  const point = focalPoint || viewerCenterPoint();

  currentZoom = clampedZoom;
  applyZoom();

  if (previousZoom === 0 || previousZoom === currentZoom) {
    return;
  }

  const zoomRatio = currentZoom / previousZoom;
  viewer.scrollLeft = (viewer.scrollLeft + point.x) * zoomRatio - point.x;
  viewer.scrollTop = (viewer.scrollTop + point.y) * zoomRatio - point.y;
}

function applyZoom() {
  document.documentElement.style.setProperty('--preview-page-width', `${Math.round(currentFitWidth * currentZoom)}px`);
}

function updateFitWidth() {
  currentFitWidth = Math.max(320, viewer.clientWidth - viewerHorizontalPadding);
  applyZoom();
}

function pointInViewer(event) {
  const rect = viewer.getBoundingClientRect();
  const x = Number.isFinite(event.clientX) ? event.clientX - rect.left : rect.width / 2;
  const y = Number.isFinite(event.clientY) ? event.clientY - rect.top : rect.height / 2;

  return {
    x: Math.max(0, Math.min(rect.width, x)),
    y: Math.max(0, Math.min(rect.height, y)),
  };
}

function viewerCenterPoint() {
  return {
    x: viewer.clientWidth / 2,
    y: viewer.clientHeight / 2,
  };
}

function reportDocumentSize(documentElement) {
  const firstPage = documentElement.querySelector('.page');
  const firstPageSize = pageSize(firstPage);

  if (!firstPageSize) {
    return;
  }

  reportToHost('documentSize', {
    width: Math.ceil(firstPageSize.width + viewerHorizontalPadding),
    height: Math.ceil(firstPageSize.height + viewerVerticalChrome),
  });
}

function pageSize(page) {
  const svg = page?.querySelector('svg');

  if (!svg) {
    return null;
  }

  const viewBoxSize = sizeFromViewBox(svg.getAttribute('viewBox'));
  if (viewBoxSize) {
    return viewBoxSize;
  }

  const width = numericSVGLength(svg.getAttribute('width'));
  const height = numericSVGLength(svg.getAttribute('height'));

  if (width && height) {
    return { width, height };
  }

  return null;
}

function sizeFromViewBox(viewBox) {
  if (!viewBox) {
    return null;
  }

  const values = viewBox
    .trim()
    .split(/[\s,]+/)
    .map(Number);

  if (values.length !== 4 || values.some((value) => !Number.isFinite(value))) {
    return null;
  }

  const width = Math.abs(values[2]);
  const height = Math.abs(values[3]);

  return width > 0 && height > 0 ? { width, height } : null;
}

function numericSVGLength(value) {
  if (!value) {
    return null;
  }

  const number = Number.parseFloat(value);
  return Number.isFinite(number) && number > 0 ? number : null;
}

function reportToHost(level, error) {
  const message = error instanceof Error ? `${error.name}: ${error.message}` : error;
  window.webkit?.messageHandlers?.hwpPreviewLog?.postMessage({ level, message });
}

function decodeBase64(base64) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  return bytes;
}
