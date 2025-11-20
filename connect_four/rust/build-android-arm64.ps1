rustup target add aarch64-linux-android
$env:CLANG_PATH="C:\dev\android-sdk\ndk\28.1.13356709\toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"
$env:CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="C:\dev\android-sdk\ndk\28.1.13356709\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android34-clang.cmd"
cargo build --target=aarch64-linux-android
cargo build --target=aarch64-linux-android --release
