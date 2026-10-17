{ config, pkgs, ... }:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "36" ];
    includeNDK = true;
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "arm64-v8a" "x86_64" ];
  };

  androidSdk = androidComposition.androidsdk;
  sdkRoot = "${androidSdk}/libexec/android-sdk";
  ndkRoot = "${sdkRoot}/ndk-bundle"; # or specific version path inside ${sdkRoot}/ndk
in
{
  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  environment.systemPackages = [ androidSdk pkgs.jdk17 ];

  environment.variables = {
    ANDROID_HOME = sdkRoot;
    ANDROID_SDK_ROOT = sdkRoot;
    ANDROID_AVD_HOME = "$HOME/.config/.android/avd";
    # NDK_HOME is required if you are compiling C/C++ native code
    NDK_HOME = ndkRoot;
    
  };
}