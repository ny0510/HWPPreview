# Third-Party Notices

HWPPreview bundles third-party software to render HWP/HWPX documents in the Quick Look preview extension.

## rhwp

- Project: rhwp
- Purpose: HWP/HWPX parsing and WebAssembly/SVG rendering
- Upstream repository: https://github.com/edwardkim/rhwp
- License: MIT
- Bundled files: `HWPQuickLookPreview/Web/rhwp.js`, `HWPQuickLookPreview/Web/rhwp_bg.wasm`
- Reference commit checked during license review: `a9dcdee32b17a7f9a20c609a5ed547e62fb8ebae`
- Upstream third-party dependency notices: https://github.com/edwardkim/rhwp/blob/main/THIRD_PARTY_LICENSES.md

The upstream project publishes `rhwp` and related packages under the MIT License. Its transitive Rust/WASM dependencies are documented upstream and include permissive licenses such as MIT, Apache-2.0, BSD-3-Clause, Unlicense, and Zlib. If bundled `rhwp` assets are updated, review the upstream license and third-party notices again.

### rhwp MIT License Notice

MIT License

Copyright (c) 2025-2026 Edward Kim

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
