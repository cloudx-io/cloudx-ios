//
//  CLXExport.h
//  CloudXCore
//
//  Symbol-visibility macros. Public classes, extern constants, and C
//  functions must be annotated with one of these macros or they will not
//  be exported from the CloudXCore.framework binary.
//
//  CLX_PUBLIC            — publisher-facing API (CLXBanner, CLXInterstitial, …)
//  CLX_PUBLIC_ADAPTER    — adapter-facing API (CLXAdapterAdView, factories, …)
//  CLX_INTERNAL_TESTING  — exported only for internal demo/test harness; not
//                          sanctioned for publisher or adapter consumption
//
//  All three macros expand to the same attribute — the distinction is
//  author intent and reviewer signal. The Clang linker cannot distinguish
//  consumer type. Mirrors Android's public / @RestrictTo(LIBRARY_GROUP)
//  / internal visibility model, with an extra iOS-only tier because the
//  demo apps consume the same prebuilt binary end-users receive.
//

#ifndef CLXExport_h
#define CLXExport_h

#define CLX_PUBLIC            __attribute__((visibility("default")))
#define CLX_PUBLIC_ADAPTER    __attribute__((visibility("default")))
#define CLX_INTERNAL_TESTING  __attribute__((visibility("default")))

#endif /* CLXExport_h */
