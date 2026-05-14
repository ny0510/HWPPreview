# HWPPreview

[![Release](https://img.shields.io/github/v/release/ny0510/HWPPreview?style=flat-square)](https://github.com/ny0510/HWPPreview/releases)
[![Downloads](https://img.shields.io/github/downloads/ny0510/HWPPreview/total?style=flat-square)](https://github.com/ny0510/HWPPreview/releases)
[![macOS](https://img.shields.io/badge/macOS-15.0%2B-black?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

Finder에서 `.hwp`, `.hwpx` 한글 문서를 바로 훑어볼 수 있게 해주는 macOS Quick Look 확장입니다. 별도 문서 뷰어를 열지 않아도 파일을 선택하고 Space만 누르면 미리보기를 확인할 수 있습니다.

## Screenshot

![HWPPreview Quick Look preview](docs/screenshots/hwppreview.png)

## Features

- Finder Quick Look에서 `.hwp`, `.hwpx` 문서 미리보기
- 트랙패드 핀치 제스처로 문서 확대 및 축소
- 문서 미리보기만 남긴 가벼운 WebView 렌더러
- `rhwp` 기반 HWP/HWPX 파싱 및 SVG 렌더링

## Installation

### 로컬 빌드 권장

HWPPreview는 Quick Look 확장을 포함하므로, Apple Developer ID로 서명하고 공증하지 않은 배포 빌드는 macOS에서 확장이 등록되지 않거나 표시되지 않을 수 있습니다. 안정적으로 사용하려면 클론한 뒤 로컬 Xcode에서 직접 빌드하세요.

```sh
git clone https://github.com/ny0510/HWPPreview.git
cd HWPPreview
```

1. Xcode에서 `HWPPreview.xcodeproj`를 엽니다.
2. `HWPPreview` 앱 스킴을 선택합니다.
3. `Product` > `Archive`로 로컬에서 아카이브합니다.
4. Organizer에서 앱을 내보낸 뒤 `HWPPreview.app`을 `/Applications` 폴더로 이동합니다.
5. 앱을 한 번 실행해 Quick Look 확장을 macOS에 등록합니다.

### Homebrew / GitHub Releases

> Homebrew와 GitHub Releases의 바이너리 빌드는 Apple Developer ID로 서명하거나 공증하지 않았기 때문에 Quick Look 확장이 정상적으로 활성화되지 않을 수 있습니다. 인증서 문제를 피하려면 위 로컬 빌드 방식을 사용하세요.

- Homebrew: `brew install --cask ny0510/tap/hwppreview`
- [GitHub Releases](https://github.com/ny0510/HWPPreview/releases)

## Usage

1. `HWPPreview.app`을 한 번 실행합니다.
2. 시스템 설정에서 `일반` > `로그인 항목 및 확장 프로그램` > `Quick Look`으로 이동합니다.
3. `HWPPreview` Quick Look 확장을 켭니다.
4. Finder에서 `.hwp` 또는 `.hwpx` 파일을 선택하고 Space를 누릅니다.

## Troubleshooting

Quick Look 확장을 켰는데도 미리보기가 표시되지 않으면 아래 순서대로 확인하세요.

```sh
qlmanage -r
qlmanage -r cache
killall Finder
```

다운로드한 바이너리 빌드를 사용할 경우 macOS의 보안 정책으로 인해 "앱이 손상되었으므로 열 수 없습니다"라는 오류가 발생하거나 Quick Look 확장이 보이지 않을 수 있습니다. 이 경우 로컬 빌드를 권장합니다. 임시로 계속 사용하려면 앱을 `/Applications`로 옮긴 뒤 아래 명령으로 격리 속성을 제거하고, 앱을 한 번 실행한 후 Quick Look 확장을 다시 켜세요.

```sh
xattr -dr com.apple.quarantine /Applications/HWPPreview.app
```

## Contributing

버그 리포트, 기능 제안, 코드 기여 모두 환영합니다! GitHub Issues나 Pull Requests를 통해 참여해주세요.

## License

HWPPreview는 [MIT License](LICENSE)로 배포됩니다.

이 프로젝트는 HWP/HWPX 문서 파싱과 렌더링을 위해 MIT 라이선스의 [`rhwp`](https://github.com/edwardkim/rhwp)를 번들합니다. 자세한 서드파티 고지는 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참고하세요.
