/*
    Created by Rainyl.
    Licensed: Apache 2.0 license. Copyright (c) 2024 Rainyl.
*/

#ifndef CVD_STITCHING_H
#define CVD_STITCHING_H

#include "dartcv/core/types.h"

#ifdef __cplusplus
#include <opencv2/stitching.hpp>
extern "C" {
#endif

enum {
    STITCHING_PANORAMA = 0,
    STITCHING_SCANS = 1
};
enum {
    STITCHING_OK = 0,
    STITCHING_ERR_NEED_MORE_IMGS = 1,
    STITCHING_ERR_HOMOGRAPHY_EST_FAIL = 2,
    STITCHING_ERR_CAMERA_PARAMS_ADJUST_FAIL = 3
};

// cv::detail::WaveCorrectKind
enum {
    STITCHING_WAVE_CORRECT_HORIZ = 0,
    STITCHING_WAVE_CORRECT_VERT = 1,
    STITCHING_WAVE_CORRECT_AUTO = 2
};

// Projection surface that a cv::WarperCreator builds warpers for. `a`/`b` in
// cv_WarperCreator_create are only read by the four parametric projections
// (compressed rectilinear and panini); the others ignore them.
enum {
    STITCHING_WARPER_PLANE = 0,
    STITCHING_WARPER_AFFINE = 1,
    STITCHING_WARPER_CYLINDRICAL = 2,
    STITCHING_WARPER_SPHERICAL = 3,
    STITCHING_WARPER_FISHEYE = 4,
    STITCHING_WARPER_STEREOGRAPHIC = 5,
    STITCHING_WARPER_COMPRESSED_RECTILINEAR = 6,
    STITCHING_WARPER_COMPRESSED_RECTILINEAR_PORTRAIT = 7,
    STITCHING_WARPER_PANINI = 8,
    STITCHING_WARPER_PANINI_PORTRAIT = 9,
    STITCHING_WARPER_MERCATOR = 10,
    STITCHING_WARPER_TRANSVERSE_MERCATOR = 11
};

// Feature detector used as a Stitcher features finder. `nfeatures` in
// cv_FeaturesFinder_create caps the detected keypoints where the detector
// supports it (ORB's nfeatures, SIFT's nfeatures, AKAZE's max_points); pass 0 or
// less for the detector's own default. BRISK has no such cap and ignores it.
enum {
    STITCHING_FINDER_ORB = 0,
    STITCHING_FINDER_SIFT = 1,
    STITCHING_FINDER_AKAZE = 2,
    STITCHING_FINDER_BRISK = 3
};

// cv::detail::FeaturesMatcher implementations. RANGE only matches each image
// against its `range_width` neighbours, which is what an ordered turntable or
// video capture wants; AFFINE pairs with the affine estimator/bundle adjuster.
enum {
    STITCHING_MATCHER_BEST_OF_2_NEAREST = 0,
    STITCHING_MATCHER_BEST_OF_2_NEAREST_RANGE = 1,
    STITCHING_MATCHER_AFFINE_BEST_OF_2_NEAREST = 2
};

// cv::detail::Estimator implementations.
enum {
    STITCHING_ESTIMATOR_HOMOGRAPHY = 0,
    STITCHING_ESTIMATOR_AFFINE = 1
};

// cv::detail::BundleAdjusterBase implementations.
enum {
    STITCHING_BUNDLE_ADJUSTER_NO = 0,
    STITCHING_BUNDLE_ADJUSTER_REPROJ = 1,
    STITCHING_BUNDLE_ADJUSTER_RAY = 2,
    STITCHING_BUNDLE_ADJUSTER_AFFINE = 3,
    STITCHING_BUNDLE_ADJUSTER_AFFINE_PARTIAL = 4
};

// cv::detail::ExposureCompensator::createDefault types; values match OpenCV's.
enum {
    STITCHING_EXPOSURE_NO = 0,
    STITCHING_EXPOSURE_GAIN = 1,
    STITCHING_EXPOSURE_GAIN_BLOCKS = 2,
    STITCHING_EXPOSURE_CHANNELS = 3,
    STITCHING_EXPOSURE_CHANNELS_BLOCKS = 4
};

// cv::detail::SeamFinder implementations, flattening each class's cost function
// into the type so one enum selects the whole seam strategy.
enum {
    STITCHING_SEAM_NO = 0,
    STITCHING_SEAM_VORONOI = 1,
    STITCHING_SEAM_DP_COLOR = 2,
    STITCHING_SEAM_DP_COLOR_GRAD = 3,
    STITCHING_SEAM_GRAPH_CUT_COLOR = 4,
    STITCHING_SEAM_GRAPH_CUT_COLOR_GRAD = 5
};

// cv::detail::Blender::createDefault types; values match OpenCV's.
enum {
    STITCHING_BLENDER_NO = 0,
    STITCHING_BLENDER_FEATHER = 1,
    STITCHING_BLENDER_MULTI_BAND = 2
};

#ifdef __cplusplus
CVD_TYPEDEF(cv::Ptr<cv::Stitcher>, Stitcher);
CVD_TYPEDEF(cv::Ptr<cv::WarperCreator>, WarperCreator);
CVD_TYPEDEF(cv::Ptr<cv::detail::RotationWarper>, RotationWarper);
CVD_TYPEDEF(cv::Ptr<cv::Feature2D>, FeaturesFinder);
CVD_TYPEDEF(cv::Ptr<cv::detail::FeaturesMatcher>, FeaturesMatcher);
CVD_TYPEDEF(cv::Ptr<cv::detail::Estimator>, Estimator);
CVD_TYPEDEF(cv::Ptr<cv::detail::BundleAdjusterBase>, BundleAdjuster);
CVD_TYPEDEF(cv::Ptr<cv::detail::ExposureCompensator>, ExposureCompensator);
CVD_TYPEDEF(cv::Ptr<cv::detail::SeamFinder>, SeamFinder);
CVD_TYPEDEF(cv::Ptr<cv::detail::Blender>, Blender);
CVD_TYPEDEF_STD_VEC(cv::detail::CameraParams, VecCameraParams);
#else
CVD_TYPEDEF(void*, Stitcher);
CVD_TYPEDEF(void*, WarperCreator);
CVD_TYPEDEF(void*, RotationWarper);
CVD_TYPEDEF(void*, FeaturesFinder);
CVD_TYPEDEF(void*, FeaturesMatcher);
CVD_TYPEDEF(void*, Estimator);
CVD_TYPEDEF(void*, BundleAdjuster);
CVD_TYPEDEF(void*, ExposureCompensator);
CVD_TYPEDEF(void*, SeamFinder);
CVD_TYPEDEF(void*, Blender);
CVD_TYPEDEF_STD_VEC(void, VecCameraParams);
#endif

CvStatus* cv_Stitcher_create(int mode, Stitcher* rval);
void cv_Stitcher_close(StitcherPtr stitcher);

#pragma region getter/setter

double cv_Stitcher_get_registrationResol(Stitcher self);
void cv_Stitcher_set_registrationResol(Stitcher self, double val);

double cv_Stitcher_get_seamEstimationResol(Stitcher self);
void cv_Stitcher_set_seamEstimationResol(Stitcher self, double val);

double cv_Stitcher_get_compositingResol(Stitcher self);
void cv_Stitcher_set_compositingResol(Stitcher self, double val);

double cv_Stitcher_get_panoConfidenceThresh(Stitcher self);
void cv_Stitcher_set_panoConfidenceThresh(Stitcher self, double val);

bool cv_Stitcher_get_waveCorrection(Stitcher self);
void cv_Stitcher_set_waveCorrection(Stitcher self, bool val);

int cv_Stitcher_get_interpolationFlags(Stitcher self);
void cv_Stitcher_set_interpolationFlags(Stitcher self, int val);

int cv_Stitcher_get_waveCorrectKind(Stitcher self);
void cv_Stitcher_set_waveCorrectKind(Stitcher self, int val);

// Scale the registration step ran at, i.e. the ratio between the resolution
// features were found at and the full input resolution. Camera parameters
// returned by cv_Stitcher_cameras are expressed at that scale.
double cv_Stitcher_get_workScale(Stitcher self);

// The projection surface the panorama is composed onto. The default is
// spherical for STITCHING_PANORAMA and affine for STITCHING_SCANS; cylindrical
// is the one that fits labels wrapped around a bottle or a can. The getter hands
// back a new handle owning a reference to the stitcher's current creator; the
// caller must release it with cv_WarperCreator_close.
CvStatus* cv_Stitcher_get_warper(Stitcher self, WarperCreator* rval);
CvStatus* cv_Stitcher_set_warper(Stitcher self, WarperCreator warper);
#pragma endregion

#pragma region functions

CvStatus* cv_Stitcher_estimateTransform(
    Stitcher self, VecMat mats, VecMat masks, int* rval, CvCallback_0 callback
);

// Restores the camera rotations and intrinsics estimated by a previous
// cv_Stitcher_estimateTransform, optionally after editing them (see
// cv_detail_waveCorrect). `component` may be an empty vector, in which case
// every image is used.
CvStatus* cv_Stitcher_setTransform(
    Stitcher self,
    VecMat mats,
    VecCameraParams cameras,
    VecI32 component,
    int* rval,
    CvCallback_0 callback
);

CvStatus* cv_Stitcher_composePanorama(Stitcher self, Mat rpano, int* rval, CvCallback_0 callback);
CvStatus* cv_Stitcher_composePanorama_1(
    Stitcher self, VecMat mats, Mat rpano, int* rval, CvCallback_0 callback
);

CvStatus* cv_Stitcher_stitch(
    Stitcher self, VecMat mats, Mat rpano, int* rval, CvCallback_0 callback
);
CvStatus* cv_Stitcher_stitch_1(
    Stitcher self, VecMat mats, VecMat masks, Mat rpano, int* rval, CvCallback_0 callback
);

CvStatus* cv_Stitcher_component(Stitcher self, VecI32* rval, CvCallback_0 callback);

// Camera parameters estimated for every stitched image, assigned into `rval`,
// which must come from cv_VecCameraParams_new.
CvStatus* cv_Stitcher_cameras(Stitcher self, VecCameraParams* rval, CvCallback_0 callback);

// 8U mask of the composed panorama: 255 where a source image contributed,
// 0 elsewhere. `rmask` must be an allocated Mat and is overwritten.
CvStatus* cv_Stitcher_resultMask(Stitcher self, Mat rmask, CvCallback_0 callback);
#pragma endregion

#pragma region WarperCreator

// Builds one of the cv::WarperCreator factories, see the STITCHING_WARPER_*
// enum. Only the parametric projections read `a` and `b` (both default to 1 in
// OpenCV).
CvStatus* cv_WarperCreator_create(int type, float a, float b, WarperCreator* rval);
void cv_WarperCreator_close(WarperCreatorPtr self);

// Instantiates the warper this factory creates at the given scale, usually the
// median focal length of the cameras.
CvStatus* cv_WarperCreator_createWarper(WarperCreator self, float scale, RotationWarper* rval);
#pragma endregion

#pragma region RotationWarper

// Convenience constructor equivalent to cv_WarperCreator_create followed by
// cv_WarperCreator_createWarper.
CvStatus* cv_RotationWarper_create(int type, float a, float b, float scale, RotationWarper* rval);
void cv_RotationWarper_close(RotationWarperPtr self);

float cv_RotationWarper_get_scale(RotationWarper self);
void cv_RotationWarper_set_scale(RotationWarper self, float val);

CvStatus* cv_RotationWarper_warpPoint(
    RotationWarper self, CvPoint2f pt, Mat K, Mat R, CvPoint2f* rval, CvCallback_0 callback
);
CvStatus* cv_RotationWarper_warpPointBackward(
    RotationWarper self, CvPoint2f pt, Mat K, Mat R, CvPoint2f* rval, CvCallback_0 callback
);

CvStatus* cv_RotationWarper_buildMaps(
    RotationWarper self,
    CvSize src_size,
    Mat K,
    Mat R,
    Mat xmap,
    Mat ymap,
    CvRect* rval,
    CvCallback_0 callback
);

CvStatus* cv_RotationWarper_warp(
    RotationWarper self,
    Mat src,
    Mat K,
    Mat R,
    int interp_mode,
    int border_mode,
    Mat dst,
    CvPoint* rval,
    CvCallback_0 callback
);

CvStatus* cv_RotationWarper_warpBackward(
    RotationWarper self,
    Mat src,
    Mat K,
    Mat R,
    int interp_mode,
    int border_mode,
    CvSize dst_size,
    Mat dst,
    CvCallback_0 callback
);

CvStatus* cv_RotationWarper_warpRoi(
    RotationWarper self, CvSize src_size, Mat K, Mat R, CvRect* rval, CvCallback_0 callback
);
#pragma endregion

#pragma region VecCameraParams

// Allocates the vector natively, so it is released by cv_VecCameraParams_close
// alone — the caller never allocates the wrapper struct itself.
VecCameraParams* cv_VecCameraParams_new(size_t length);
void cv_VecCameraParams_close(VecCameraParamsPtr self);
size_t cv_VecCameraParams_length(VecCameraParams self);

// Reads element `index`. `R` and `t` must be allocated Mats and are overwritten
// with copies, so they stay valid after the vector is freed.
CvStatus* cv_VecCameraParams_get(
    VecCameraParams self,
    int index,
    double* focal,
    double* aspect,
    double* ppx,
    double* ppy,
    Mat R,
    Mat t,
    CvCallback_0 callback
);

// Overwrites element `index`; `R` and `t` are copied.
CvStatus* cv_VecCameraParams_set(
    VecCameraParams self,
    int index,
    double focal,
    double aspect,
    double ppx,
    double ppy,
    Mat R,
    Mat t,
    CvCallback_0 callback
);
#pragma endregion

#pragma region pipeline components

// Every setter below replaces one stage of the stitching pipeline; each getter
// hands back a new handle sharing ownership with the stitcher, which the caller
// releases with the matching _close. Mixing homography-model and affine-model
// stages produces meaningless results — see the OpenCV stitching docs.

// --- features finder (cv::Feature2D) ---
// Built here rather than taken from the features2d module: dartcv keeps module
// bindings independent, and there is no shared C handle for cv::Ptr<Feature2D>.
CvStatus* cv_FeaturesFinder_create(int type, int nfeatures, FeaturesFinder* rval);
void cv_FeaturesFinder_close(FeaturesFinderPtr self);

CvStatus* cv_Stitcher_get_featuresFinder(Stitcher self, FeaturesFinder* rval);
CvStatus* cv_Stitcher_set_featuresFinder(Stitcher self, FeaturesFinder finder);

// --- features matcher (cv::detail::FeaturesMatcher) ---
// `range_width` is only read by STITCHING_MATCHER_BEST_OF_2_NEAREST_RANGE and
// `full_affine` only by STITCHING_MATCHER_AFFINE_BEST_OF_2_NEAREST.
//
// `matches_confidence_thresh` zeroes the confidence of any pair scoring above it,
// OpenCV's guard against matching two near-identical images. Only
// STITCHING_MATCHER_BEST_OF_2_NEAREST takes it; the other two have no
// constructor parameter for it and always use OpenCV's default of 3.
CvStatus* cv_FeaturesMatcher_create(
    int type,
    int range_width,
    bool full_affine,
    bool try_use_gpu,
    float match_conf,
    int num_matches_thresh1,
    int num_matches_thresh2,
    double matches_confidence_thresh,
    FeaturesMatcher* rval
);
void cv_FeaturesMatcher_close(FeaturesMatcherPtr self);
bool cv_FeaturesMatcher_isThreadSafe(FeaturesMatcher self);
CvStatus* cv_FeaturesMatcher_collectGarbage(FeaturesMatcher self);

CvStatus* cv_Stitcher_get_featuresMatcher(Stitcher self, FeaturesMatcher* rval);
CvStatus* cv_Stitcher_set_featuresMatcher(Stitcher self, FeaturesMatcher matcher);

// Square 8U mask over image pairs: element (i, j) non-zero means "consider
// matching image i against image j". Restricting it to neighbours is the cheap
// way to stop an ordered capture matching across the whole sequence.
CvStatus* cv_Stitcher_get_matchingMask(Stitcher self, Mat rval, CvCallback_0 callback);
CvStatus* cv_Stitcher_set_matchingMask(Stitcher self, Mat mask);

// --- estimator (cv::detail::Estimator) ---
// `is_focals_estimated` is only read by STITCHING_ESTIMATOR_HOMOGRAPHY.
CvStatus* cv_Estimator_create(int type, bool is_focals_estimated, Estimator* rval);
void cv_Estimator_close(EstimatorPtr self);

CvStatus* cv_Stitcher_get_estimator(Stitcher self, Estimator* rval);
CvStatus* cv_Stitcher_set_estimator(Stitcher self, Estimator estimator);

// --- bundle adjuster (cv::detail::BundleAdjusterBase) ---
CvStatus* cv_BundleAdjuster_create(int type, BundleAdjuster* rval);
void cv_BundleAdjuster_close(BundleAdjusterPtr self);

double cv_BundleAdjuster_get_confThresh(BundleAdjuster self);
void cv_BundleAdjuster_set_confThresh(BundleAdjuster self, double val);

// 3x3 CV_8U mask marking which intrinsics the adjuster is allowed to refine
// (fx, skew, ppx / ., fy, ppy / ., ., .); non-zero means refine. Pinning the
// principal point and aspect is what stabilises a fixed-lens rig.
CvStatus* cv_BundleAdjuster_get_refinementMask(BundleAdjuster self, Mat rval, CvCallback_0 callback);
CvStatus* cv_BundleAdjuster_set_refinementMask(BundleAdjuster self, Mat mask);

TermCriteria cv_BundleAdjuster_get_termCriteria(BundleAdjuster self);
void cv_BundleAdjuster_set_termCriteria(BundleAdjuster self, TermCriteria val);

CvStatus* cv_Stitcher_get_bundleAdjuster(Stitcher self, BundleAdjuster* rval);
CvStatus* cv_Stitcher_set_bundleAdjuster(Stitcher self, BundleAdjuster adjuster);

// --- exposure compensator (cv::detail::ExposureCompensator) ---
CvStatus* cv_ExposureCompensator_create(int type, ExposureCompensator* rval);
void cv_ExposureCompensator_close(ExposureCompensatorPtr self);

bool cv_ExposureCompensator_get_updateGain(ExposureCompensator self);
void cv_ExposureCompensator_set_updateGain(ExposureCompensator self, bool val);

// The five accessors below exist only on the block-based compensators
// (STITCHING_EXPOSURE_GAIN_BLOCKS / _CHANNELS_BLOCKS) and fail with a
// CvStatus on any other kind.
CvStatus* cv_ExposureCompensator_get_blockSize(ExposureCompensator self, CvSize* rval);
CvStatus* cv_ExposureCompensator_set_blockSize(ExposureCompensator self, CvSize val);
CvStatus* cv_ExposureCompensator_get_nrFeeds(ExposureCompensator self, int* rval);
CvStatus* cv_ExposureCompensator_set_nrFeeds(ExposureCompensator self, int val);
CvStatus* cv_ExposureCompensator_get_nrGainsFilteringIterations(ExposureCompensator self, int* rval);
CvStatus* cv_ExposureCompensator_set_nrGainsFilteringIterations(ExposureCompensator self, int val);
CvStatus* cv_ExposureCompensator_get_similarityThreshold(ExposureCompensator self, double* rval);
CvStatus* cv_ExposureCompensator_set_similarityThreshold(ExposureCompensator self, double val);

CvStatus* cv_Stitcher_get_exposureCompensator(Stitcher self, ExposureCompensator* rval);
CvStatus* cv_Stitcher_set_exposureCompensator(Stitcher self, ExposureCompensator compensator);

// --- seam finder (cv::detail::SeamFinder) ---
// `terminal_cost` and `bad_region_penalty` are only read by the graph-cut kinds.
CvStatus* cv_SeamFinder_create(
    int type, float terminal_cost, float bad_region_penalty, SeamFinder* rval
);
void cv_SeamFinder_close(SeamFinderPtr self);

CvStatus* cv_Stitcher_get_seamFinder(Stitcher self, SeamFinder* rval);
CvStatus* cv_Stitcher_set_seamFinder(Stitcher self, SeamFinder finder);

// --- blender (cv::detail::Blender) ---
CvStatus* cv_Blender_create(int type, bool try_gpu, Blender* rval);
void cv_Blender_close(BlenderPtr self);

// sharpness belongs to the feather blender and numBands to the multi-band one;
// each fails with a CvStatus on the other kinds.
CvStatus* cv_Blender_get_sharpness(Blender self, float* rval);
CvStatus* cv_Blender_set_sharpness(Blender self, float val);
CvStatus* cv_Blender_get_numBands(Blender self, int* rval);
CvStatus* cv_Blender_set_numBands(Blender self, int val);

CvStatus* cv_Stitcher_get_blender(Stitcher self, Blender* rval);
CvStatus* cv_Stitcher_set_blender(Stitcher self, Blender blender);
#pragma endregion

#pragma region rotation estimation

// cv::detail::waveCorrect. Straightens a panorama by rotating every camera so
// the horizon stays level; `rmats` is modified in place and its elements must be
// 3x3 CV_32F. STITCHING_WAVE_CORRECT_AUTO picks the kind per
// cv_detail_autoDetectWaveCorrectKind.
CvStatus* cv_detail_waveCorrect(VecMat rmats, int kind, CvCallback_0 callback);

// cv::detail::autoDetectWaveCorrectKind. Reports whether the panorama spans
// horizontally or vertically, as a STITCHING_WAVE_CORRECT_* value.
CvStatus* cv_detail_autoDetectWaveCorrectKind(VecMat rmats, int* rval, CvCallback_0 callback);
#pragma endregion

#ifdef __cplusplus
}
#endif

#endif  // CVD_STITCHING_H
