import init, { HwpDocument } from './rhwp.js';

const status = document.getElementById('status');
const viewer = document.getElementById('viewer');

let wasmReady = null;
let canvasContext = null;
let lastMeasuredFont = '';

window.addEventListener('error', (event) => {
  reportToHost('error', event.error || event.message || 'Unknown JavaScript error');
});

window.addEventListener('unhandledrejection', (event) => {
  reportToHost('error', event.reason || 'Unhandled JavaScript promise rejection');
});

setStatus('HWP Preview', '렌더러 스크립트 로드 완료');

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
  setStatus('HWP Preview', '렌더러 초기화 중...');

  wasmReady
    .then(() => setStatus('HWP Preview', '렌더러 준비 완료'))
    .catch((error) => {
      wasmReady = null;
      renderError(error);
      setStatus('HWP Preview', '렌더러 초기화 실패');
    });
};

window.renderHWPPreview = async (payload) => {
  try {
    if (!wasmReady) {
      throw new Error('rhwp WASM has not been initialized.');
    }

    setStatus(payload.fileName, '문서를 파싱하는 중...');
    viewer.replaceChildren();

    await wasmReady;

    const bytes = decodeBase64(payload.base64);
    const hwpDocument = new HwpDocument(bytes);

    try {
      const pageCount = hwpDocument.pageCount();

      if (pageCount <= 0) {
        renderEmpty('표시할 페이지가 없습니다.');
        setStatus(payload.fileName, '0 페이지');
        return;
      }

      setStatus(payload.fileName, `${pageCount}페이지 렌더링 중...`);

      for (let pageIndex = 0; pageIndex < pageCount; pageIndex += 1) {
        const page = document.createElement('article');
        page.className = 'page';
        page.dataset.page = String(pageIndex + 1);
        page.innerHTML = hwpDocument.renderPageSvg(pageIndex);
        viewer.appendChild(page);
      }

      setStatus(payload.fileName, `${pageCount}페이지`);
    } finally {
      hwpDocument.free();
    }
  } catch (error) {
    renderError(error);
    setStatus(payload.fileName || 'HWP Preview', '렌더링 실패');
  }
};

window.showHWPPreviewError = (payload) => {
  const message = payload && payload.message ? payload.message : String(payload);
  renderError(new Error(message));
  setStatus('HWP Preview', '오류');
};

function setStatus(title, message) {
  if (!status) {
    return;
  }

  status.replaceChildren();

  const titleElement = document.createElement('strong');
  titleElement.textContent = title;

  const messageElement = document.createElement('span');
  messageElement.textContent = message;

  status.append(titleElement, messageElement);
}

function renderEmpty(message) {
  const element = document.createElement('section');
  element.className = 'empty';
  element.textContent = message;
  viewer.replaceChildren(element);
}

function renderError(error) {
  const element = document.createElement('section');
  element.className = 'error';
  element.textContent = error instanceof Error ? error.message : String(error);
  viewer.replaceChildren(element);
}

function reportToHost(level, error) {
  const message = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
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
