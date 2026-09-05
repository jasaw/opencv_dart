// Copyright (c) 2024, rainyl and all contributors. All rights reserved.
// Use of this source code is governed by a Apache-2.0 license
// that can be found in the LICENSE file.

/// The individual stages of the stitching pipeline, i.e. the `cv::detail`
/// classes a [Stitcher] can be rebuilt from.
///
/// Two camera models run through these stages and must not be mixed: the
/// *homography* model ([EstimatorType.homography], [BundleAdjusterType.ray] or
/// [BundleAdjusterType.reproj], [MatcherType.bestOf2Nearest]) and the *affine*
/// model ([EstimatorType.affine], [BundleAdjusterType.affine] or
/// [BundleAdjusterType.affinePartial], [MatcherType.affineBestOf2Nearest],
/// [WarperType.affine]). [StitcherMode.PANORAMA] preconfigures the first and
/// [StitcherMode.SCANS] the second.
library cv.stitching;

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import '../core/base.dart';
import '../core/mat.dart';
import '../core/mat_type.dart';
import '../core/size.dart';
import '../core/termcriteria.dart';
import '../g/stitching.g.dart' as cvg;
import '../g/stitching.g.dart' as cstitching;
import './stitching.dart';

/// Feature detector used to find the keypoints a [Stitcher] matches on.
///
/// [sift] is usually the best choice for printed labels and other high-contrast
/// artwork; [orb] is markedly faster and the OpenCV default.
enum FeaturesFinderType {
  orb,
  sift,
  akaze,
  brisk;

  factory FeaturesFinderType.fromInt(int v) => values.firstWhere((e) => e.index == v);

  /// Whether this detector honours [FeaturesFinder.new]'s `nfeatures` cap.
  bool get supportsFeatureCap => this != brisk;
}

/// A `cv::Feature2D` configured for use as a [Stitcher]'s features finder.
///
/// Built here rather than taken from `package:dartcv4`'s features2d detectors:
/// dartcv keeps each module's bindings independent, and OpenCV exposes no shared
/// C handle for `cv::Ptr<Feature2D>`.
class FeaturesFinder extends CvStruct<cvg.FeaturesFinder> {
  FeaturesFinder._(cvg.FeaturesFinderPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory FeaturesFinder.fromPointer(cvg.FeaturesFinderPtr ptr, [bool attach = true]) =>
      FeaturesFinder._(ptr, attach);

  /// Creates the detector for [type].
  ///
  /// [nfeatures] caps how many keypoints are kept, where the detector supports
  /// it (see [FeaturesFinderType.supportsFeatureCap]); 0 or less means the
  /// detector's own default.
  factory FeaturesFinder(FeaturesFinderType type, {int nfeatures = 0}) {
    final p = calloc<cvg.FeaturesFinder>();
    cvRun(() => cstitching.cv_FeaturesFinder_create(type.index, nfeatures, p));
    return FeaturesFinder._(p);
  }

  static final finalizer = OcvFinalizer<cvg.FeaturesFinderPtr>(
    cstitching.addresses.cv_FeaturesFinder_close,
  );

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_FeaturesFinder_close(ptr);
  }

  @override
  cvg.FeaturesFinder get ref => ptr.ref;
}

/// Strategy a [Stitcher] uses to match features between images.
enum MatcherType {
  /// Matches every image against every other one.
  bestOf2Nearest,

  /// Matches each image only against its `rangeWidth` neighbours in input
  /// order. The right choice for a turntable or video capture, where the
  /// sequence is already ordered — it is both far faster and less likely to
  /// pair up two visually similar but distant frames.
  ///
  /// Do not reuse one [Stitcher] across several stitches with this matcher.
  /// `cv::Stitcher` keeps its pairwise matches between `stitch()` calls and only
  /// clears them in `setTransform`, and this matcher refills just the
  /// neighbouring pairs, so every other slot still holds the previous stitch's
  /// data. As soon as the image count changes the `i * n + j` layout shifts,
  /// those stale entries surface as arbitrary pairs, and the estimator inverts
  /// an empty homography — a `-215` assertion from `invert`, on the second
  /// stitch onwards. Build a [Stitcher] per stitch instead;
  /// [MatcherType.bestOf2Nearest] does not have the problem because it
  /// overwrites every pair.
  bestOf2NearestRange,

  /// Like [bestOf2Nearest] but estimates an affine transform, for the affine
  /// camera model.
  affineBestOf2Nearest;

  factory MatcherType.fromInt(int v) => values.firstWhere((e) => e.index == v);
}

/// A `cv::detail::FeaturesMatcher`.
class FeaturesMatcher extends CvStruct<cvg.FeaturesMatcher> {
  FeaturesMatcher._(cvg.FeaturesMatcherPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory FeaturesMatcher.fromPointer(cvg.FeaturesMatcherPtr ptr, [bool attach = true]) =>
      FeaturesMatcher._(ptr, attach);

  /// Creates the matcher for [type].
  ///
  /// [rangeWidth] is read only by [MatcherType.bestOf2NearestRange] and
  /// [fullAffine] only by [MatcherType.affineBestOf2Nearest]; the remaining
  /// parameters carry OpenCV's own defaults. [numMatchesThresh2] is ignored by
  /// [MatcherType.affineBestOf2Nearest], which reuses [numMatchesThresh1].
  ///
  /// [matchesConfidenceThresh] zeroes the confidence of any image pair scoring
  /// above it — OpenCV's guard against stitching two near-duplicate frames.
  /// A dense detector such as [FeaturesFinderType.sift] can trip it on
  /// legitimately overlapping images, since confidence is
  /// `inliers / (8 + 0.3 * matches)` and approaches 3.33 as the inlier ratio
  /// approaches 1; the symptom is [StitcherStatus.ERR_NEED_MORE_IMGS] from a
  /// pair that plainly overlaps. Raising it past 3.33 disables the guard.
  /// Only [MatcherType.bestOf2Nearest] accepts it — OpenCV gives the other two
  /// no constructor parameter for it, so they are stuck on the default of 3.
  factory FeaturesMatcher(
    MatcherType type, {
    int rangeWidth = 5,
    bool fullAffine = false,
    bool tryUseGpu = false,
    double matchConf = 0.3,
    int numMatchesThresh1 = 6,
    int numMatchesThresh2 = 6,
    double matchesConfidenceThresh = 3,
  }) {
    final p = calloc<cvg.FeaturesMatcher>();
    cvRun(
      () => cstitching.cv_FeaturesMatcher_create(
        type.index,
        rangeWidth,
        fullAffine,
        tryUseGpu,
        matchConf,
        numMatchesThresh1,
        numMatchesThresh2,
        matchesConfidenceThresh,
        p,
      ),
    );
    return FeaturesMatcher._(p);
  }

  bool get isThreadSafe => cstitching.cv_FeaturesMatcher_isThreadSafe(ref);

  /// Frees the matcher's internal buffers.
  void collectGarbage() => cvRun(() => cstitching.cv_FeaturesMatcher_collectGarbage(ref));

  static final finalizer = OcvFinalizer<cvg.FeaturesMatcherPtr>(
    cstitching.addresses.cv_FeaturesMatcher_close,
  );

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_FeaturesMatcher_close(ptr);
  }

  @override
  cvg.FeaturesMatcher get ref => ptr.ref;
}

/// Camera-parameter estimator, i.e. which camera model the pipeline assumes.
enum EstimatorType {
  homography,
  affine;

  factory EstimatorType.fromInt(int v) => values.firstWhere((e) => e.index == v);
}

/// A `cv::detail::Estimator`.
class Estimator extends CvStruct<cvg.Estimator> {
  Estimator._(cvg.EstimatorPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory Estimator.fromPointer(cvg.EstimatorPtr ptr, [bool attach = true]) => Estimator._(ptr, attach);

  /// Creates the estimator for [type]. [isFocalsEstimated] is read only by
  /// [EstimatorType.homography].
  factory Estimator(EstimatorType type, {bool isFocalsEstimated = false}) {
    final p = calloc<cvg.Estimator>();
    cvRun(() => cstitching.cv_Estimator_create(type.index, isFocalsEstimated, p));
    return Estimator._(p);
  }

  static final finalizer = OcvFinalizer<cvg.EstimatorPtr>(cstitching.addresses.cv_Estimator_close);

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_Estimator_close(ptr);
  }

  @override
  cvg.Estimator get ref => ptr.ref;
}

/// Bundle adjustment refinement used after the initial camera estimate.
enum BundleAdjusterType {
  /// Skips refinement entirely.
  no,

  /// Minimises reprojection error.
  reproj,

  /// Minimises ray divergence; OpenCV's default for panoramas and generally the
  /// more stable of the two homography adjusters.
  ray,

  /// Affine model, 6 degrees of freedom.
  affine,

  /// Affine model, 4 degrees of freedom (rotation, translation, uniform scale).
  affinePartial;

  factory BundleAdjusterType.fromInt(int v) => values.firstWhere((e) => e.index == v);
}

/// A `cv::detail::BundleAdjusterBase`.
class BundleAdjuster extends CvStruct<cvg.BundleAdjuster> {
  BundleAdjuster._(cvg.BundleAdjusterPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory BundleAdjuster.fromPointer(cvg.BundleAdjusterPtr ptr, [bool attach = true]) =>
      BundleAdjuster._(ptr, attach);

  factory BundleAdjuster(BundleAdjusterType type) {
    final p = calloc<cvg.BundleAdjuster>();
    cvRun(() => cstitching.cv_BundleAdjuster_create(type.index, p));
    return BundleAdjuster._(p);
  }

  /// Images with a pairwise match confidence below this are dropped from the
  /// panorama.
  double get confThresh => cstitching.cv_BundleAdjuster_get_confThresh(ref);
  set confThresh(double value) => cstitching.cv_BundleAdjuster_set_confThresh(ref, value);

  /// 3x3 CV_8U mask of the intrinsics the adjuster may refine, laid out like the
  /// camera matrix — `(0,0)` focal, `(0,1)` skew, `(0,2)` ppx, `(1,1)` aspect,
  /// `(1,2)` ppy. Non-zero means refine; OpenCV starts with all ones.
  ///
  /// Pinning the principal point and aspect is what stabilises a fixed-lens rig
  /// shooting a turntable, where the true intrinsics never change between
  /// frames and letting them drift only adds noise:
  ///
  /// ```dart
  /// final mask = cv.Mat.zeros(3, 3, cv.MatType.CV_8UC1);
  /// mask.set<int>(0, 0, 1); // refine focal length only
  /// adjuster.refinementMask = mask;
  /// ```
  Mat get refinementMask {
    final m = Mat.empty();
    cvRun(() => cstitching.cv_BundleAdjuster_get_refinementMask(ref, m.ref, ffi.nullptr));
    return m;
  }

  set refinementMask(Mat value) =>
      cvRun(() => cstitching.cv_BundleAdjuster_set_refinementMask(ref, value.ref));

  TermCriteria get termCriteria {
    final tc = cstitching.cv_BundleAdjuster_get_termCriteria(ref);
    return TermCriteria(tc.type, tc.maxCount, tc.epsilon);
  }

  set termCriteria(TermCriteria value) => cstitching.cv_BundleAdjuster_set_termCriteria(ref, value.ref);

  static final finalizer = OcvFinalizer<cvg.BundleAdjusterPtr>(
    cstitching.addresses.cv_BundleAdjuster_close,
  );

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_BundleAdjuster_close(ptr);
  }

  @override
  cvg.BundleAdjuster get ref => ptr.ref;
}

/// How brightness differences between overlapping images are evened out.
enum ExposureCompensatorType {
  no,

  /// One gain per image.
  gain,

  /// A grid of gains per image. The right choice when the lighting varies
  /// *across* a frame rather than uniformly — a specular highlight sliding over
  /// a can as it turns, for instance.
  gainBlocks,

  /// One gain per colour channel per image, which also corrects colour casts.
  channels,

  /// A grid of per-channel gains: [gainBlocks] and [channels] combined.
  channelsBlocks;

  factory ExposureCompensatorType.fromInt(int v) => values.firstWhere((e) => e.index == v);

  /// Whether this kind supports [ExposureCompensator.blockSize] and the other
  /// block-only settings.
  bool get isBlockBased => this == gainBlocks || this == channelsBlocks;
}

/// A `cv::detail::ExposureCompensator`.
class ExposureCompensator extends CvStruct<cvg.ExposureCompensator> {
  ExposureCompensator._(cvg.ExposureCompensatorPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory ExposureCompensator.fromPointer(cvg.ExposureCompensatorPtr ptr, [bool attach = true]) =>
      ExposureCompensator._(ptr, attach);

  factory ExposureCompensator(ExposureCompensatorType type) {
    final p = calloc<cvg.ExposureCompensator>();
    cvRun(() => cstitching.cv_ExposureCompensator_create(type.index, p));
    return ExposureCompensator._(p);
  }

  /// Whether gains are recomputed on the next feed, rather than reused.
  bool get updateGain => cstitching.cv_ExposureCompensator_get_updateGain(ref);
  set updateGain(bool value) => cstitching.cv_ExposureCompensator_set_updateGain(ref, value);

  /// Size of one gain block. Block-based kinds only — see
  /// [ExposureCompensatorType.isBlockBased]; throws otherwise.
  Size get blockSize {
    final p = calloc<cvg.CvSize>();
    cvRun(() => cstitching.cv_ExposureCompensator_get_blockSize(ref, p));
    return Size.fromPointer(p);
  }

  set blockSize(Size value) => cvRun(() => cstitching.cv_ExposureCompensator_set_blockSize(ref, value.ref));

  /// Number of feed iterations. Block-based kinds only; throws otherwise.
  int get nrFeeds => _getInt(cstitching.cv_ExposureCompensator_get_nrFeeds);
  set nrFeeds(int value) => cvRun(() => cstitching.cv_ExposureCompensator_set_nrFeeds(ref, value));

  /// Number of gain-map filtering passes. Block-based kinds only; throws
  /// otherwise.
  int get nrGainsFilteringIterations =>
      _getInt(cstitching.cv_ExposureCompensator_get_nrGainsFilteringIterations);

  set nrGainsFilteringIterations(int value) =>
      cvRun(() => cstitching.cv_ExposureCompensator_set_nrGainsFilteringIterations(ref, value));

  /// Threshold below which neighbouring blocks are treated as similar.
  /// Block-based kinds only; throws otherwise.
  double get similarityThreshold {
    final p = calloc<ffi.Double>();
    try {
      cvRun(() => cstitching.cv_ExposureCompensator_get_similarityThreshold(ref, p));
      return p.value;
    } finally {
      calloc.free(p);
    }
  }

  set similarityThreshold(double value) =>
      cvRun(() => cstitching.cv_ExposureCompensator_set_similarityThreshold(ref, value));

  int _getInt(
    ffi.Pointer<cvg.CvStatus> Function(cvg.ExposureCompensator, ffi.Pointer<ffi.Int>) native,
  ) {
    final p = calloc<ffi.Int>();
    try {
      cvRun(() => native(ref, p));
      return p.value;
    } finally {
      calloc.free(p);
    }
  }

  static final finalizer = OcvFinalizer<cvg.ExposureCompensatorPtr>(
    cstitching.addresses.cv_ExposureCompensator_close,
  );

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_ExposureCompensator_close(ptr);
  }

  @override
  cvg.ExposureCompensator get ref => ptr.ref;
}

/// How the seam between two overlapping images is chosen.
enum SeamFinderType {
  /// No seam search; images are blended over their whole overlap.
  no,

  /// Splits the overlap down the middle. Cheapest.
  voronoi,

  /// Dynamic programming on colour difference.
  dpColor,

  /// Dynamic programming on colour and gradient difference.
  dpColorGrad,

  /// Graph cut on colour difference. Slowest and usually the best looking.
  graphCutColor,

  /// Graph cut on colour and gradient difference; OpenCV's default.
  graphCutColorGrad;

  factory SeamFinderType.fromInt(int v) => values.firstWhere((e) => e.index == v);

  /// Whether this kind reads [SeamFinder.new]'s `terminalCost` and
  /// `badRegionPenalty`.
  bool get isGraphCut => this == graphCutColor || this == graphCutColorGrad;
}

/// A `cv::detail::SeamFinder`.
class SeamFinder extends CvStruct<cvg.SeamFinder> {
  SeamFinder._(cvg.SeamFinderPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory SeamFinder.fromPointer(cvg.SeamFinderPtr ptr, [bool attach = true]) => SeamFinder._(ptr, attach);

  /// Creates the seam finder for [type]. [terminalCost] and [badRegionPenalty]
  /// are read only by the graph-cut kinds — see [SeamFinderType.isGraphCut].
  factory SeamFinder(
    SeamFinderType type, {
    double terminalCost = 10000,
    double badRegionPenalty = 1000,
  }) {
    final p = calloc<cvg.SeamFinder>();
    cvRun(() => cstitching.cv_SeamFinder_create(type.index, terminalCost, badRegionPenalty, p));
    return SeamFinder._(p);
  }

  static final finalizer = OcvFinalizer<cvg.SeamFinderPtr>(cstitching.addresses.cv_SeamFinder_close);

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_SeamFinder_close(ptr);
  }

  @override
  cvg.SeamFinder get ref => ptr.ref;
}

/// How the warped images are merged into the final panorama.
enum BlenderType {
  /// Plain overwrite, seams stay visible.
  no,

  /// Linear cross-fade over the seam; see [Blender.sharpness].
  feather,

  /// Laplacian-pyramid blending; see [Blender.numBands]. OpenCV's default and
  /// the best at hiding exposure steps across a seam.
  multiBand;

  factory BlenderType.fromInt(int v) => values.firstWhere((e) => e.index == v);
}

/// A `cv::detail::Blender`.
class Blender extends CvStruct<cvg.Blender> {
  Blender._(cvg.BlenderPtr ptr, [bool attach = true]) : super.fromPointer(ptr) {
    if (attach) {
      finalizer.attach(this, ptr.cast(), detach: this);
    }
  }

  factory Blender.fromPointer(cvg.BlenderPtr ptr, [bool attach = true]) => Blender._(ptr, attach);

  factory Blender(BlenderType type, {bool tryGpu = false}) {
    final p = calloc<cvg.Blender>();
    cvRun(() => cstitching.cv_Blender_create(type.index, tryGpu, p));
    return Blender._(p);
  }

  /// Width of the feathered transition, as an inverse: larger is sharper.
  /// [BlenderType.feather] only; throws otherwise.
  double get sharpness {
    final p = calloc<ffi.Float>();
    try {
      cvRun(() => cstitching.cv_Blender_get_sharpness(ref, p));
      return p.value;
    } finally {
      calloc.free(p);
    }
  }

  set sharpness(double value) => cvRun(() => cstitching.cv_Blender_set_sharpness(ref, value));

  /// Number of pyramid levels blended. [BlenderType.multiBand] only; throws
  /// otherwise.
  int get numBands {
    final p = calloc<ffi.Int>();
    try {
      cvRun(() => cstitching.cv_Blender_get_numBands(ref, p));
      return p.value;
    } finally {
      calloc.free(p);
    }
  }

  set numBands(int value) => cvRun(() => cstitching.cv_Blender_set_numBands(ref, value));

  static final finalizer = OcvFinalizer<cvg.BlenderPtr>(cstitching.addresses.cv_Blender_close);

  @override
  void freeNative() {
    finalizer.detach(this);
    cstitching.cv_Blender_close(ptr);
  }

  @override
  cvg.Blender get ref => ptr.ref;
}

/// The pipeline stages of a [Stitcher].
///
/// Each setter replaces one stage; each getter returns a new handle that shares
/// ownership with the stitcher, so disposing it does not disturb the stitcher.
/// Setting a stage keeps the object alive natively, so the Dart handle may be
/// discarded straight after assigning it.
extension StitcherPipeline on Stitcher {
  /// The detector used to find keypoints. Default ORB.
  FeaturesFinder get featuresFinder {
    final p = calloc<cvg.FeaturesFinder>();
    cvRun(() => cstitching.cv_Stitcher_get_featuresFinder(ref, p));
    return FeaturesFinder.fromPointer(p);
  }

  set featuresFinder(FeaturesFinder value) =>
      cvRun(() => cstitching.cv_Stitcher_set_featuresFinder(ref, value.ref));

  /// The strategy used to match features between images.
  FeaturesMatcher get featuresMatcher {
    final p = calloc<cvg.FeaturesMatcher>();
    cvRun(() => cstitching.cv_Stitcher_get_featuresMatcher(ref, p));
    return FeaturesMatcher.fromPointer(p);
  }

  set featuresMatcher(FeaturesMatcher value) =>
      cvRun(() => cstitching.cv_Stitcher_set_featuresMatcher(ref, value.ref));

  /// Square CV_8U mask over image pairs: a non-zero at `(i, j)` means image `i`
  /// is allowed to match image `j`. Empty by default, which means "match every
  /// pair".
  ///
  /// [sequentialMatchingMask] builds the band-diagonal mask an ordered capture
  /// wants. Setting a mask requires it to be square and CV_8U.
  Mat get matchingMask {
    final m = Mat.empty();
    cvRun(() => cstitching.cv_Stitcher_get_matchingMask(ref, m.ref, ffi.nullptr));
    return m;
  }

  set matchingMask(Mat value) => cvRun(() => cstitching.cv_Stitcher_set_matchingMask(ref, value.ref));

  /// The camera model used for the initial parameter estimate.
  Estimator get estimator {
    final p = calloc<cvg.Estimator>();
    cvRun(() => cstitching.cv_Stitcher_get_estimator(ref, p));
    return Estimator.fromPointer(p);
  }

  set estimator(Estimator value) => cvRun(() => cstitching.cv_Stitcher_set_estimator(ref, value.ref));

  /// The refinement applied to the estimated camera parameters.
  BundleAdjuster get bundleAdjuster {
    final p = calloc<cvg.BundleAdjuster>();
    cvRun(() => cstitching.cv_Stitcher_get_bundleAdjuster(ref, p));
    return BundleAdjuster.fromPointer(p);
  }

  set bundleAdjuster(BundleAdjuster value) =>
      cvRun(() => cstitching.cv_Stitcher_set_bundleAdjuster(ref, value.ref));

  /// How brightness differences between images are evened out.
  ExposureCompensator get exposureCompensator {
    final p = calloc<cvg.ExposureCompensator>();
    cvRun(() => cstitching.cv_Stitcher_get_exposureCompensator(ref, p));
    return ExposureCompensator.fromPointer(p);
  }

  set exposureCompensator(ExposureCompensator value) =>
      cvRun(() => cstitching.cv_Stitcher_set_exposureCompensator(ref, value.ref));

  /// How the seam between overlapping images is chosen.
  SeamFinder get seamFinder {
    final p = calloc<cvg.SeamFinder>();
    cvRun(() => cstitching.cv_Stitcher_get_seamFinder(ref, p));
    return SeamFinder.fromPointer(p);
  }

  set seamFinder(SeamFinder value) => cvRun(() => cstitching.cv_Stitcher_set_seamFinder(ref, value.ref));

  /// How the warped images are merged into the final panorama.
  Blender get blender {
    final p = calloc<cvg.Blender>();
    cvRun(() => cstitching.cv_Stitcher_get_blender(ref, p));
    return Blender.fromPointer(p);
  }

  set blender(Blender value) => cvRun(() => cstitching.cv_Stitcher_set_blender(ref, value.ref));
}

/// Builds the [StitcherPipeline.matchingMask] for a capture whose images are
/// already in order, such as a turntable revolution or a video walk-through.
///
/// Image `i` is matched only against the [range] images on either side of it,
/// which both speeds matching up and stops two similar-looking but distant
/// frames being paired. When [loop] is true the band wraps around the ends, as a
/// full revolution does when its last frame meets its first.
///
/// The result is a [count] x [count] CV_8U matrix, ready to assign:
///
/// ```dart
/// stitcher.featuresMatcher = cv.FeaturesMatcher(
///   cv.MatcherType.bestOf2NearestRange,
///   rangeWidth: 2,
/// );
/// stitcher.matchingMask = cv.sequentialMatchingMask(images.length, range: 2);
/// ```
///
/// Note this is a dartcv convenience, not an OpenCV API.
Mat sequentialMatchingMask(int count, {int range = 2, bool loop = true}) {
  if (count < 0) {
    throw ArgumentError.value(count, 'count', 'must not be negative');
  }
  if (range < 1) {
    throw ArgumentError.value(range, 'range', 'must be at least 1');
  }
  final mask = Mat.zeros(count, count, MatType.CV_8UC1);
  for (var i = 0; i < count; i++) {
    for (var d = 1; d <= range; d++) {
      final forward = i + d;
      if (forward < count) {
        mask.set<int>(i, forward, 1);
        mask.set<int>(forward, i, 1);
      } else if (loop) {
        final wrapped = forward % count;
        // With few images a wide range can wrap all the way onto i itself; the
        // diagonal is meaningless to the matcher, so leave it clear.
        if (wrapped != i) {
          mask.set<int>(i, wrapped, 1);
          mask.set<int>(wrapped, i, 1);
        }
      }
    }
  }
  return mask;
}
