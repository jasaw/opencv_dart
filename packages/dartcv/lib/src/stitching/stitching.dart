// Copyright (c) 2024, rainyl and all contributors. All rights reserved.
// Use of this source code is governed by a Apache-2.0 license
// that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

library cv.stitching;

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import '../core/base.dart';
import '../core/mat.dart';
import '../core/mat_type.dart';
import '../core/point.dart';
import '../core/rect.dart';
import '../core/size.dart';
import '../core/vec.dart';
import '../g/constants.g.dart';
import '../g/stitching.g.dart' as cvg;
import '../g/stitching.g.dart' as cstitching;

/// High level image stitcher.
///
/// It's possible to use this class without being aware of the entire
/// stitching pipeline. However, to be able to achieve higher stitching
/// stability and quality of the final images at least being familiar
/// with the theory is recommended.
/// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#details
class Stitcher extends CvStruct<cvg.Stitcher> {
  Stitcher._(cvg.StitcherPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }
  factory Stitcher.fromPointer(cvg.StitcherPtr ptr, [bool attach = true]) => Stitcher._(ptr.cast(), attach);

  /// Creates a Stitcher configured in one of the stitching modes.
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a308a47865a1f381e4429c8ec5e99549f
  factory Stitcher.create({StitcherMode mode = StitcherMode.PANORAMA}) {
    final ptr_ = calloc<cvg.Stitcher>();
    cvRun(() => cstitching.cv_Stitcher_create(mode.index, ptr_));
    return Stitcher._(ptr_);
  }

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a9b90774eabdf68c9ee864918d620538d
  double get registrationResol => cstitching.cv_Stitcher_get_registrationResol(ref);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a9912fe8c095b8385267908e5ef707439
  set registrationResol(double value) => cstitching.cv_Stitcher_set_registrationResol(ref, value);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#ac559c3eb228614f9402ff3eba23a08f5
  double get seamEstimationResol => cstitching.cv_Stitcher_get_seamEstimationResol(ref);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#ad0fcef52b2fedda1dbb90ea780cd7979
  set seamEstimationResol(double value) => cstitching.cv_Stitcher_set_seamEstimationResol(ref, value);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#ad13d2d50b253e471fbaf041b9a044571
  double get compositingResol => cstitching.cv_Stitcher_get_compositingResol(ref);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#afe927e80fcb2ca2061630ddd98eebba8
  set compositingResol(double value) => cstitching.cv_Stitcher_set_compositingResol(ref, value);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a3755bbeca7f4c80dc42af034f7621568
  double get panoConfidenceThresh => cstitching.cv_Stitcher_get_panoConfidenceThresh(ref);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a6f5e62bc1dd5d7bdb5f9313a2c21c558
  set panoConfidenceThresh(double value) => cstitching.cv_Stitcher_set_panoConfidenceThresh(ref, value);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#af6a51e0b23dac119a3612d57345f9a7f
  bool get waveCorrection => cstitching.cv_Stitcher_get_waveCorrection(ref);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a968a2f4a1faddfdacbcfce54b44bab70
  set waveCorrection(bool value) => cstitching.cv_Stitcher_set_waveCorrection(ref, value);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#abc0c8f54a1d223a1098206654813d973
  int get interpolationFlags => cstitching.cv_Stitcher_get_interpolationFlags(ref);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a253d04b8dcd3c674321b29139c769873
  set interpolationFlags(int value) => cstitching.cv_Stitcher_set_interpolationFlags(ref, value);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#ad9c9c9b8a97b686ad3b93f7918c4c6de
  int get waveCorrectKind => cstitching.cv_Stitcher_get_waveCorrectKind(ref);

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a17413f5c06e4e569bfd45e01d4e8ff4a
  set waveCorrectKind(int value) => cstitching.cv_Stitcher_set_waveCorrectKind(ref, value);

  /// Scale the registration step ran at, i.e. the ratio between the resolution
  /// features were found at and the full input resolution.
  ///
  /// [cameras] are expressed at this scale, so a focal length in full-resolution
  /// pixels is `camera.focal / workScale`.
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html
  double get workScale => cstitching.cv_Stitcher_get_workScale(ref);

  /// Sets the projection surface the panorama is composed onto.
  ///
  /// The default is [WarperType.spherical] for [StitcherMode.PANORAMA] and
  /// [WarperType.affine] for [StitcherMode.SCANS]. [WarperType.cylindrical] is
  /// the one that fits a label wrapped around a bottle or a can — a spherical
  /// projection bows such a label vertically, a cylindrical one does not.
  ///
  /// The getter reports the creator currently installed, but not which
  /// projection it builds — OpenCV keeps only a `Ptr<WarperCreator>`, whose type
  /// is not introspectable. It is still usable, e.g. to copy the projection onto
  /// another stitcher or to build the pipeline's own warper via
  /// [WarperCreator.createWarper].
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html
  WarperCreator get warper {
    final p = calloc<cvg.WarperCreator>();
    cvRun(() => cstitching.cv_Stitcher_get_warper(ref, p));
    return WarperCreator.fromPointer(p);
  }

  set warper(WarperCreator value) => cvRun(() => cstitching.cv_Stitcher_set_warper(ref, value.ref));

  /// These functions try to match the given images and to estimate rotations of each camera.
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a4c25557af4d40a79a4d1f23d9548131d
  StitcherStatus estimateTransform(VecMat images, {VecMat? masks}) {
    final rptr = calloc<ffi.Int>();
    masks ??= VecMat.fromList([]);
    cvRun(() => cstitching.cv_Stitcher_estimateTransform(ref, images.ref, masks!.ref, rptr, ffi.nullptr));
    final rval = StitcherStatus.fromInt(rptr.value);
    calloc.free(rptr);
    return rval;
  }

  /// Restores the camera rotations and intrinsics estimated by a previous
  /// [estimateTransform], usually after editing them — see [waveCorrect].
  ///
  /// [component] are the 0-based indices of the images making up the panorama,
  /// as reported by [component]; when omitted every image is used.
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html
  StitcherStatus setTransform(VecMat images, List<CameraParams> cameras, {List<int>? component}) {
    final rptr = calloc<ffi.Int>();
    final vec = VecCameraParams.fromList(cameras);
    final comp = VecI32.fromList(component ?? <int>[]);
    try {
      cvRun(
        () => cstitching.cv_Stitcher_setTransform(ref, images.ref, vec.ref, comp.ref, rptr, ffi.nullptr),
      );
      return StitcherStatus.fromInt(rptr.value);
    } finally {
      calloc.free(rptr);
      vec.dispose();
      comp.dispose();
    }
  }

  /// These functions try to compose the given images (or images stored internally
  /// from the other function calls) into the final pano under the assumption
  /// that the image transformations were estimated before.
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#acc8409a6b2e548de1653f0dc5c2ccb02
  (StitcherStatus, Mat pano) composePanorama({VecMat? images}) {
    final rptr = calloc<ffi.Int>();
    final rpano = Mat.empty();
    images == null
        ? cvRun(() => cstitching.cv_Stitcher_composePanorama(ref, rpano.ref, rptr, ffi.nullptr))
        : cvRun(
            () => cstitching.cv_Stitcher_composePanorama_1(ref, images.ref, rpano.ref, rptr, ffi.nullptr),
          );
    final rval = (StitcherStatus.fromInt(rptr.value), rpano);
    calloc.free(rptr);
    return rval;
  }

  /// This is an overloaded member function, provided for convenience.
  /// It differs from the above function only in what argument(s) it accepts.
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a37ee5bacf229e9d0fb9f97c8f5ed1acd
  (StitcherStatus, Mat pano) stitch(VecMat images, {VecMat? masks}) {
    final rptr = calloc<ffi.Int>();
    final rpano = Mat.empty();
    masks == null
        ? cvRun(() => cstitching.cv_Stitcher_stitch(ref, images.ref, rpano.ref, rptr, ffi.nullptr))
        : cvRun(
            () => cstitching.cv_Stitcher_stitch_1(ref, images.ref, masks.ref, rpano.ref, rptr, ffi.nullptr),
          );
    final rval = (StitcherStatus.fromInt(rptr.value), rpano);
    calloc.free(rptr);
    return rval;
  }

  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a7fed80561a9b46a1a924ac6cb334ac85
  VecI32 get component {
    final v = VecI32();
    cvRun(() => cstitching.cv_Stitcher_component(ref, v.ptr, ffi.nullptr));
    return v;
  }

  /// Camera parameters estimated for every stitched image, in the order given by
  /// [component]. Only meaningful after [estimateTransform] or [stitch].
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html
  List<CameraParams> get cameras {
    final vec = VecCameraParams();
    try {
      cvRun(() => cstitching.cv_Stitcher_cameras(ref, vec.ptr, ffi.nullptr));
      return vec.toList();
    } finally {
      vec.dispose();
    }
  }

  /// 8U mask of the composed panorama: 255 where a source image contributed,
  /// 0 elsewhere. Useful as the mask for `inpaint`, or to crop the pano to its
  /// filled region. Only meaningful after [composePanorama] or [stitch].
  /// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html
  Mat get resultMask {
    final mask = Mat.empty();
    cvRun(() => cstitching.cv_Stitcher_resultMask(ref, mask.ref, ffi.nullptr));
    return mask;
  }

  static final finalizer = OcvFinalizer<cvg.StitcherPtr>(cstitching.addresses.cv_Stitcher_close);

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_Stitcher_close(ptr);
  }

  @override
  cvg.Stitcher get ref => ptr.ref;
}

/// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a507409ce9435dd89857469d12ec06b45
enum StitcherStatus {
  OK,
  ERR_NEED_MORE_IMGS,
  ERR_HOMOGRAPHY_EST_FAIL,
  ERR_CAMERA_PARAMS_ADJUST_FAIL;

  factory StitcherStatus.fromInt(int v) => values.firstWhere((e) => e.index == v);
}

/// https://docs.opencv.org/4.x/d2/d8d/classcv_1_1Stitcher.html#a114713924ec05a0309f4df7e918c0324
enum StitcherMode {
  /// Mode for creating photo panoramas. Expects images under perspective transformation and projects resulting pano to sphere.
  PANORAMA,

  /// Mode for composing scans. Expects images under affine transformation does not compensate exposure by default.
  SCANS;

  factory StitcherMode.fromInt(int v) => values.firstWhere((e) => e.index == v);
}

/// https://docs.opencv.org/4.x/d7/d74/group__stitching__rotation.html#ga83b24d4c3e93584986a56d9e43b9cf7f
enum WaveCorrectKind {
  HORIZONTAL,
  VERTICAL,

  /// Detects whether the panorama spans horizontally or vertically and applies
  /// that kind, see [autoDetectWaveCorrectKind].
  AUTO;

  factory WaveCorrectKind.fromInt(int v) => values.firstWhere((e) => e.index == v);
}

/// The projection surface a [WarperCreator] builds warpers for.
///
/// Wraps `cv::WarperCreator`.
enum WarperType {
  plane,
  affine,
  cylindrical,
  spherical,
  fisheye,
  stereographic,
  compressedRectilinear,
  compressedRectilinearPortrait,
  panini,
  paniniPortrait,
  mercator,
  transverseMercator;

  factory WarperType.fromInt(int v) => values.firstWhere((e) => e.index == v);

  /// Whether this projection reads the `a` and `b` parameters of
  /// [WarperCreator.new] and [RotationWarper.new].
  bool get isParametric =>
      this == compressedRectilinear ||
      this == compressedRectilinearPortrait ||
      this == panini ||
      this == paniniPortrait;
}

/// Factory for the image warper the stitching pipeline projects onto, i.e. the
/// shape of the panorama's canvas.
///
/// Pass one to [Stitcher.warper] to override the mode's default projection:
///
/// ```dart
/// final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
/// stitcher.warper = cv.WarperCreator(cv.WarperType.cylindrical);
/// ```
///
/// Wraps `cv::WarperCreator`.
class WarperCreator extends CvStruct<cvg.WarperCreator> {
  WarperCreator._(cvg.WarperCreatorPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory WarperCreator.fromPointer(cvg.WarperCreatorPtr ptr, [bool attach = true]) =>
      WarperCreator._(ptr, attach);

  /// Creates the factory for [type].
  ///
  /// [a] and [b] are only read by the parametric projections — see
  /// [WarperType.isParametric] — and both default to OpenCV's own default of 1.
  factory WarperCreator(WarperType type, {double a = 1, double b = 1}) {
    final p = calloc<cvg.WarperCreator>();
    cvRun(() => cstitching.cv_WarperCreator_create(type.index, a, b, p));
    return WarperCreator._(p);
  }

  /// Instantiates the warper this factory creates, at [scale] — usually the
  /// median focal length of the estimated cameras.
  RotationWarper createWarper(double scale) {
    final p = calloc<cvg.RotationWarper>();
    cvRun(() => cstitching.cv_WarperCreator_createWarper(ref, scale, p));
    return RotationWarper.fromPointer(p);
  }

  static final finalizer = OcvFinalizer<cvg.WarperCreatorPtr>(
    cstitching.addresses.cv_WarperCreator_close,
  );

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_WarperCreator_close(ptr);
  }

  @override
  cvg.WarperCreator get ref => ptr.ref;
}

/// Rotation-only model image warper, i.e. `cv::detail::RotationWarper`.
///
/// Projects a single image onto a surface given the camera intrinsics `K` and
/// rotation `R`, independently of [Stitcher]. This is what unrolls one photo of
/// a curved label onto a flat strip:
///
/// ```dart
/// final warper = cv.RotationWarper(cv.WarperType.cylindrical, focal);
/// final (corner, warped) = warper.warp(img, K, R);
/// ```
///
/// `K` must be 3x3 CV_32F and `R` 3x3 CV_32F, matching what OpenCV's stitching
/// pipeline produces.
///
/// Wraps `cv::detail::RotationWarper`.
class RotationWarper extends CvStruct<cvg.RotationWarper> {
  RotationWarper._(cvg.RotationWarperPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory RotationWarper.fromPointer(cvg.RotationWarperPtr ptr, [bool attach = true]) =>
      RotationWarper._(ptr, attach);

  /// Creates the warper for [type] at [scale], equivalent to
  /// `WarperCreator(type, a: a, b: b).createWarper(scale)`.
  factory RotationWarper(WarperType type, double scale, {double a = 1, double b = 1}) {
    final p = calloc<cvg.RotationWarper>();
    cvRun(() => cstitching.cv_RotationWarper_create(type.index, a, b, scale, p));
    return RotationWarper._(p);
  }

  double get scale => cstitching.cv_RotationWarper_get_scale(ref);
  set scale(double value) => cstitching.cv_RotationWarper_set_scale(ref, value);

  /// Projects the image point [pt].
  Point2f warpPoint(Point2f pt, Mat K, Mat R) {
    final p = calloc<cvg.CvPoint2f>();
    cvRun(() => cstitching.cv_RotationWarper_warpPoint(ref, pt.ref, K.ref, R.ref, p, ffi.nullptr));
    return Point2f.fromPointer(p);
  }

  /// Projects the image point [pt] backward, i.e. from the warped plane back to
  /// the source image.
  Point2f warpPointBackward(Point2f pt, Mat K, Mat R) {
    final p = calloc<cvg.CvPoint2f>();
    cvRun(() => cstitching.cv_RotationWarper_warpPointBackward(ref, pt.ref, K.ref, R.ref, p, ffi.nullptr));
    return Point2f.fromPointer(p);
  }

  /// Builds the projection maps for an image of [srcSize], for use with `remap`.
  ///
  /// Returns the projected image's bounding box together with the x and y maps.
  ///
  /// Mind the off-by-one OpenCV carries here: the returned rect spans the
  /// bounding box's *inclusive* corners, so the maps — and the image [warp]
  /// produces — are one pixel wider and taller than `roi.width`/`roi.height`.
  /// [warpRoi] returns that same box already made exclusive, so its size is the
  /// warped image's size.
  (Rect roi, Mat xmap, Mat ymap) buildMaps(Size srcSize, Mat K, Mat R) {
    final rect = calloc<cvg.CvRect>();
    final xmap = Mat.empty();
    final ymap = Mat.empty();
    cvRun(
      () => cstitching.cv_RotationWarper_buildMaps(
        ref,
        srcSize.ref,
        K.ref,
        R.ref,
        xmap.ref,
        ymap.ref,
        rect,
        ffi.nullptr,
      ),
    );
    return (Rect.fromPointer(rect), xmap, ymap);
  }

  /// Projects [src], returning the top-left corner of the projected image and
  /// the image itself.
  (Point corner, Mat dst) warp(
    Mat src,
    Mat K,
    Mat R, {
    int interpMode = INTER_LINEAR,
    int borderMode = BORDER_REFLECT,
  }) {
    final p = calloc<cvg.CvPoint>();
    final dst = Mat.empty();
    cvRun(
      () => cstitching.cv_RotationWarper_warp(
        ref,
        src.ref,
        K.ref,
        R.ref,
        interpMode,
        borderMode,
        dst.ref,
        p,
        ffi.nullptr,
      ),
    );
    return (Point.fromPointer(p), dst);
  }

  /// Projects the already warped [src] back into an image of [dstSize].
  Mat warpBackward(
    Mat src,
    Mat K,
    Mat R,
    Size dstSize, {
    int interpMode = INTER_LINEAR,
    int borderMode = BORDER_REFLECT,
  }) {
    final dst = Mat.empty();
    cvRun(
      () => cstitching.cv_RotationWarper_warpBackward(
        ref,
        src.ref,
        K.ref,
        R.ref,
        interpMode,
        borderMode,
        dstSize.ref,
        dst.ref,
        ffi.nullptr,
      ),
    );
    return dst;
  }

  /// The bounding box an image of [srcSize] projects to, without doing the
  /// projection. Its size is exactly the size of the image [warp] would return,
  /// unlike the inclusive box from [buildMaps].
  Rect warpRoi(Size srcSize, Mat K, Mat R) {
    final rect = calloc<cvg.CvRect>();
    cvRun(() => cstitching.cv_RotationWarper_warpRoi(ref, srcSize.ref, K.ref, R.ref, rect, ffi.nullptr));
    return Rect.fromPointer(rect);
  }

  static final finalizer = OcvFinalizer<cvg.RotationWarperPtr>(
    cstitching.addresses.cv_RotationWarper_close,
  );

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_RotationWarper_close(ptr);
  }

  @override
  cvg.RotationWarper get ref => ptr.ref;
}

/// Parameters of one camera in the stitching pipeline, i.e.
/// `cv::detail::CameraParams`.
///
/// Translation is assumed to be zero throughout the pipeline, so [t] is
/// normally a 3x1 zero matrix and only [R] and the intrinsics matter.
///
/// Wraps `cv::detail::CameraParams`.
class CameraParams {
  CameraParams({
    required this.focal,
    required this.aspect,
    required this.ppx,
    required this.ppy,
    required this.R,
    required this.t,
  });

  /// A camera with OpenCV's defaults: unit focal length and aspect, principal
  /// point at the origin, identity rotation and zero translation.
  factory CameraParams.empty() => CameraParams(
    focal: 1,
    aspect: 1,
    ppx: 0,
    ppy: 0,
    R: Mat.eye(3, 3, MatType.CV_64FC1),
    t: Mat.zeros(3, 1, MatType.CV_64FC1),
  );

  /// Focal length, in pixels at [Stitcher.workScale].
  double focal;

  /// Aspect ratio.
  double aspect;

  /// Principal point x.
  double ppx;

  /// Principal point y.
  double ppy;

  /// 3x3 rotation matrix, CV_32F as produced by the stitching pipeline.
  Mat R;

  /// 3x1 translation, assumed zero by the pipeline.
  Mat t;

  /// The 3x3 CV_64F intrinsics matrix built from [focal], [aspect], [ppx] and
  /// [ppy], matching `cv::detail::CameraParams::K()`.
  Mat get K => Mat.from2DList([
    [focal, 0.0, ppx],
    [0.0, focal * aspect, ppy],
    [0.0, 0.0, 1.0],
  ], MatType.CV_64FC1);

  @override
  String toString() =>
      'CameraParams(focal: $focal, aspect: $aspect, ppx: $ppx, ppy: $ppy, '
      'R: ${R.rows}x${R.cols}, t: ${t.rows}x${t.cols})';
}

/// Native `std::vector<cv::detail::CameraParams>`.
///
/// Only used to move [CameraParams] across the FFI boundary; prefer
/// [Stitcher.cameras] and [Stitcher.setTransform], which hand out and take
/// plain Dart lists.
class VecCameraParams extends CvStruct<cvg.VecCameraParams> {
  VecCameraParams.fromPointer(super.ptr, [bool attach = true]) : super.fromPointer() {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory VecCameraParams([int length = 0]) =>
      VecCameraParams.fromPointer(cstitching.cv_VecCameraParams_new(length));

  factory VecCameraParams.fromList(List<CameraParams> cameras) {
    final vec = VecCameraParams(cameras.length);
    for (var i = 0; i < cameras.length; i++) {
      vec[i] = cameras[i];
    }
    return vec;
  }

  int get length => cstitching.cv_VecCameraParams_length(ref);

  CameraParams operator [](int index) {
    final focal = calloc<ffi.Double>();
    final aspect = calloc<ffi.Double>();
    final ppx = calloc<ffi.Double>();
    final ppy = calloc<ffi.Double>();
    final r = Mat.empty();
    final t = Mat.empty();
    try {
      cvRun(
        () => cstitching.cv_VecCameraParams_get(
          ref,
          index,
          focal,
          aspect,
          ppx,
          ppy,
          r.ref,
          t.ref,
          ffi.nullptr,
        ),
      );
      return CameraParams(
        focal: focal.value,
        aspect: aspect.value,
        ppx: ppx.value,
        ppy: ppy.value,
        R: r,
        t: t,
      );
    } finally {
      calloc.free(focal);
      calloc.free(aspect);
      calloc.free(ppx);
      calloc.free(ppy);
    }
  }

  void operator []=(int index, CameraParams value) => cvRun(
    () => cstitching.cv_VecCameraParams_set(
      ref,
      index,
      value.focal,
      value.aspect,
      value.ppx,
      value.ppy,
      value.R.ref,
      value.t.ref,
      ffi.nullptr,
    ),
  );

  List<CameraParams> toList() => List.generate(length, (i) => this[i]);

  static final finalizer = OcvFinalizer<cvg.VecCameraParamsPtr>(
    cstitching.addresses.cv_VecCameraParams_close,
  );

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_VecCameraParams_close(ptr);
  }

  @override
  cvg.VecCameraParams get ref => ptr.ref;
}

/// Tries to make a panorama more horizontal (or vertical) by rotating every
/// camera, i.e. `cv::detail::waveCorrect`.
///
/// [rmats] is modified in place and its elements must be 3x3 CV_32F — the type
/// [Stitcher.cameras] returns.
///
/// This is the manual counterpart of [Stitcher.waveCorrection]. That flag makes
/// [Stitcher.estimateTransform] run this correction itself, so drive the two
/// together, not both: turn the flag off, then correct between
/// [Stitcher.estimateTransform] and [Stitcher.setTransform] — which installs the
/// cameras as given, without correcting again.
///
/// ```dart
/// stitcher.waveCorrection = false;
/// stitcher.estimateTransform(images);
///
/// final cameras = stitcher.cameras;
/// final rmats = cameras.map((c) => c.R).toList().cvd;
/// cv.waveCorrect(rmats, cv.WaveCorrectKind.HORIZONTAL);
/// for (var i = 0; i < cameras.length; i++) {
///   cameras[i].R = rmats[i];
/// }
///
/// stitcher.setTransform(images, cameras);
/// final (status, pano) = stitcher.composePanorama();
/// ```
///
/// A one-element [rmats] is left untouched, as in OpenCV, and so is one whose
/// rotations are degenerate for the requested axis.
///
/// https://docs.opencv.org/4.x/d7/d74/group__stitching__rotation.html
void waveCorrect(VecMat rmats, WaveCorrectKind kind) =>
    cvRun(() => cstitching.cv_detail_waveCorrect(rmats.ref, kind.index, ffi.nullptr));

/// Detects whether a panorama spans horizontally or vertically, i.e.
/// `cv::detail::autoDetectWaveCorrectKind`.
///
/// Never returns [WaveCorrectKind.AUTO].
///
/// https://docs.opencv.org/4.x/d7/d74/group__stitching__rotation.html
WaveCorrectKind autoDetectWaveCorrectKind(VecMat rmats) {
  final rptr = calloc<ffi.Int>();
  try {
    cvRun(() => cstitching.cv_detail_autoDetectWaveCorrectKind(rmats.ref, rptr, ffi.nullptr));
    return WaveCorrectKind.fromInt(rptr.value);
  } finally {
    calloc.free(rptr);
  }
}
