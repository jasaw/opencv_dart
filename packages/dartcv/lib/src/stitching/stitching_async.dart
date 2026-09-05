// Copyright (c) 2024, rainyl and all contributors. All rights reserved.
// Use of this source code is governed by a Apache-2.0 license
// that can be found in the LICENSE file.

library cv.stitching;

import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import '../core/base.dart';
import '../core/mat.dart';
import '../core/point.dart';
import '../core/rect.dart';
import '../core/size.dart';
import '../core/vec.dart';
import '../g/constants.g.dart';
import '../g/stitching.g.dart' as cvg;
import '../g/stitching.g.dart' as cstitching;
import './stitching.dart';

extension StitcherAsync on Stitcher {
  Future<StitcherStatus> estimateTransformAsync(VecMat images, {VecMat? masks}) async {
    final rptr = calloc<ffi.Int>();
    masks ??= VecMat.fromList([]);
    return cvRunAsync0(
      (callback) => cstitching.cv_Stitcher_estimateTransform(ref, images.ref, masks!.ref, rptr, callback),
      (c) {
        final rval = StitcherStatus.fromInt(rptr.value);
        calloc.free(rptr);
        return c.complete(rval);
      },
    );
  }

  Future<StitcherStatus> setTransformAsync(
    VecMat images,
    List<CameraParams> cameras, {
    List<int>? component,
  }) async {
    final rptr = calloc<ffi.Int>();
    final vec = VecCameraParams.fromList(cameras);
    final comp = VecI32.fromList(component ?? <int>[]);
    return cvRunAsync0(
      (callback) => cstitching.cv_Stitcher_setTransform(ref, images.ref, vec.ref, comp.ref, rptr, callback),
      (c) {
        final rval = StitcherStatus.fromInt(rptr.value);
        calloc.free(rptr);
        vec.dispose();
        comp.dispose();
        return c.complete(rval);
      },
    );
  }

  Future<List<CameraParams>> camerasAsync() async {
    final vec = VecCameraParams();
    return cvRunAsync0(
      (callback) => cstitching.cv_Stitcher_cameras(ref, vec.ptr, callback),
      (c) {
        try {
          return c.complete(vec.toList());
        } finally {
          vec.dispose();
        }
      },
    );
  }

  Future<Mat> resultMaskAsync() async {
    final mask = Mat.empty();
    return cvRunAsync0(
      (callback) => cstitching.cv_Stitcher_resultMask(ref, mask.ref, callback),
      (c) => c.complete(mask),
    );
  }

  Future<(StitcherStatus, Mat)> composePanoramaAsync({VecMat? images}) async {
    final rptr = calloc<ffi.Int>();
    final rpano = Mat.empty();
    void completeFunc(Completer c) {
      final rval = (StitcherStatus.fromInt(rptr.value), rpano);
      calloc.free(rptr);
      return c.complete(rval);
    }

    if (images == null) {
      return cvRunAsync0(
        (callback) => cstitching.cv_Stitcher_composePanorama(ref, rpano.ref, rptr, callback),
        completeFunc,
      );
    }
    return cvRunAsync0(
      (callback) => cstitching.cv_Stitcher_composePanorama_1(ref, images.ref, rpano.ref, rptr, callback),
      completeFunc,
    );
  }

  Future<(StitcherStatus, Mat)> stitchAsync(VecMat images, {VecMat? masks}) async {
    final rptr = calloc<ffi.Int>();
    final rpano = Mat.empty();
    void completeFunc(Completer c) {
      final rval = (StitcherStatus.fromInt(rptr.value), rpano);
      calloc.free(rptr);
      return c.complete(rval);
    }

    if (masks == null) {
      return cvRunAsync0(
        (callback) => cstitching.cv_Stitcher_stitch(ref, images.ref, rpano.ref, rptr, callback),
        completeFunc,
      );
    }
    return cvRunAsync0(
      (callback) => cstitching.cv_Stitcher_stitch_1(ref, images.ref, masks.ref, rpano.ref, rptr, callback),
      completeFunc,
    );
  }
}

extension RotationWarperAsync on RotationWarper {
  Future<Point2f> warpPointAsync(Point2f pt, Mat K, Mat R) async {
    final p = calloc<cvg.CvPoint2f>();
    return cvRunAsync0(
      (callback) => cstitching.cv_RotationWarper_warpPoint(ref, pt.ref, K.ref, R.ref, p, callback),
      (c) => c.complete(Point2f.fromPointer(p)),
    );
  }

  Future<Point2f> warpPointBackwardAsync(Point2f pt, Mat K, Mat R) async {
    final p = calloc<cvg.CvPoint2f>();
    return cvRunAsync0(
      (callback) => cstitching.cv_RotationWarper_warpPointBackward(ref, pt.ref, K.ref, R.ref, p, callback),
      (c) => c.complete(Point2f.fromPointer(p)),
    );
  }

  Future<(Rect, Mat, Mat)> buildMapsAsync(Size srcSize, Mat K, Mat R) async {
    final rect = calloc<cvg.CvRect>();
    final xmap = Mat.empty();
    final ymap = Mat.empty();
    return cvRunAsync0(
      (callback) => cstitching.cv_RotationWarper_buildMaps(
        ref,
        srcSize.ref,
        K.ref,
        R.ref,
        xmap.ref,
        ymap.ref,
        rect,
        callback,
      ),
      (c) => c.complete((Rect.fromPointer(rect), xmap, ymap)),
    );
  }

  Future<(Point, Mat)> warpAsync(
    Mat src,
    Mat K,
    Mat R, {
    int interpMode = INTER_LINEAR,
    int borderMode = BORDER_REFLECT,
  }) async {
    final p = calloc<cvg.CvPoint>();
    final dst = Mat.empty();
    return cvRunAsync0(
      (callback) => cstitching.cv_RotationWarper_warp(
        ref,
        src.ref,
        K.ref,
        R.ref,
        interpMode,
        borderMode,
        dst.ref,
        p,
        callback,
      ),
      (c) => c.complete((Point.fromPointer(p), dst)),
    );
  }

  Future<Mat> warpBackwardAsync(
    Mat src,
    Mat K,
    Mat R,
    Size dstSize, {
    int interpMode = INTER_LINEAR,
    int borderMode = BORDER_REFLECT,
  }) async {
    final dst = Mat.empty();
    return cvRunAsync0(
      (callback) => cstitching.cv_RotationWarper_warpBackward(
        ref,
        src.ref,
        K.ref,
        R.ref,
        interpMode,
        borderMode,
        dstSize.ref,
        dst.ref,
        callback,
      ),
      (c) => c.complete(dst),
    );
  }

  Future<Rect> warpRoiAsync(Size srcSize, Mat K, Mat R) async {
    final rect = calloc<cvg.CvRect>();
    return cvRunAsync0(
      (callback) => cstitching.cv_RotationWarper_warpRoi(ref, srcSize.ref, K.ref, R.ref, rect, callback),
      (c) => c.complete(Rect.fromPointer(rect)),
    );
  }
}

/// Async variant of [waveCorrect].
Future<void> waveCorrectAsync(VecMat rmats, WaveCorrectKind kind) async => cvRunAsync0<void>(
  (callback) => cstitching.cv_detail_waveCorrect(rmats.ref, kind.index, callback),
  (c) => c.complete(),
);

/// Async variant of [autoDetectWaveCorrectKind].
Future<WaveCorrectKind> autoDetectWaveCorrectKindAsync(VecMat rmats) async {
  final rptr = calloc<ffi.Int>();
  return cvRunAsync0(
    (callback) => cstitching.cv_detail_autoDetectWaveCorrectKind(rmats.ref, rptr, callback),
    (c) {
      final rval = WaveCorrectKind.fromInt(rptr.value);
      calloc.free(rptr);
      return c.complete(rval);
    },
  );
}
