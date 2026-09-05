/*
    Created by Rainyl.
    Licensed: Apache 2.0 license. Copyright (c) 2024 Rainyl.
*/

#include "dartcv/stitching/stitching.h"
#include <opencv2/features2d.hpp>
#include <vector>
#include "dartcv/core/vec.hpp"

namespace {
// Shared by cv_WarperCreator_create and cv_RotationWarper_create. Throws a
// cv::Exception for an unknown type, which BEGIN_WRAP/END_WRAP turn into a
// CvStatus for the caller.
cv::Ptr<cv::WarperCreator> makeWarperCreator(int type, float a, float b) {
    switch (type) {
        case STITCHING_WARPER_PLANE:
            return cv::makePtr<cv::PlaneWarper>();
        case STITCHING_WARPER_AFFINE:
            return cv::makePtr<cv::AffineWarper>();
        case STITCHING_WARPER_CYLINDRICAL:
            return cv::makePtr<cv::CylindricalWarper>();
        case STITCHING_WARPER_SPHERICAL:
            return cv::makePtr<cv::SphericalWarper>();
        case STITCHING_WARPER_FISHEYE:
            return cv::makePtr<cv::FisheyeWarper>();
        case STITCHING_WARPER_STEREOGRAPHIC:
            return cv::makePtr<cv::StereographicWarper>();
        case STITCHING_WARPER_COMPRESSED_RECTILINEAR:
            return cv::makePtr<cv::CompressedRectilinearWarper>(a, b);
        case STITCHING_WARPER_COMPRESSED_RECTILINEAR_PORTRAIT:
            return cv::makePtr<cv::CompressedRectilinearPortraitWarper>(a, b);
        case STITCHING_WARPER_PANINI:
            return cv::makePtr<cv::PaniniWarper>(a, b);
        case STITCHING_WARPER_PANINI_PORTRAIT:
            return cv::makePtr<cv::PaniniPortraitWarper>(a, b);
        case STITCHING_WARPER_MERCATOR:
            return cv::makePtr<cv::MercatorWarper>();
        case STITCHING_WARPER_TRANSVERSE_MERCATOR:
            return cv::makePtr<cv::TransverseMercatorWarper>();
        default:
            CV_Error(cv::Error::StsBadArg, cv::format("unknown warper type: %d", type));
    }
}

// Narrows a pipeline component to the concrete class owning a given setting,
// reporting the mismatch instead of returning null.
template <typename Derived, typename Base>
Derived& downcastOrThrow(const cv::Ptr<Base>& p, const char* what) {
    auto* d = dynamic_cast<Derived*>(p.get());
    if (d == nullptr) {
        CV_Error(cv::Error::StsBadArg, cv::format("this component has no %s", what));
    }
    return *d;
}
}  // namespace

CvStatus* cv_Stitcher_create(int mode, Stitcher* rval) {
    BEGIN_WRAP
    const auto ptr = cv::Stitcher::create(static_cast<cv::Stitcher::Mode>(mode));
    rval->ptr = new cv::Ptr<cv::Stitcher>(ptr);
    END_WRAP
}

void cv_Stitcher_close(StitcherPtr stitcher) {
    stitcher->ptr->reset();
    CVD_FREE(stitcher);
}

double cv_Stitcher_get_registrationResol(Stitcher self) {
    return (CVDEREF(self))->registrationResol();
}
void cv_Stitcher_set_registrationResol(Stitcher self, double val) {
    (CVDEREF(self))->setRegistrationResol(val);
}

double cv_Stitcher_get_seamEstimationResol(Stitcher self) {
    return (CVDEREF(self))->seamEstimationResol();
}
void cv_Stitcher_set_seamEstimationResol(Stitcher self, double val) {
    (CVDEREF(self))->setSeamEstimationResol(val);
}

double cv_Stitcher_get_compositingResol(Stitcher self) {
    return (CVDEREF(self))->compositingResol();
}
void cv_Stitcher_set_compositingResol(Stitcher self, double val) {
    (CVDEREF(self))->setCompositingResol(val);
}

double cv_Stitcher_get_panoConfidenceThresh(Stitcher self) {
    return (CVDEREF(self))->panoConfidenceThresh();
}
void cv_Stitcher_set_panoConfidenceThresh(Stitcher self, double val) {
    (CVDEREF(self))->setPanoConfidenceThresh(val);
}

bool cv_Stitcher_get_waveCorrection(Stitcher self) {
    return (CVDEREF(self))->waveCorrection();
}
void cv_Stitcher_set_waveCorrection(Stitcher self, bool val) {
    (CVDEREF(self))->setWaveCorrection(val);
}

int cv_Stitcher_get_interpolationFlags(Stitcher self) {
    return (CVDEREF(self))->interpolationFlags();
}
void cv_Stitcher_set_interpolationFlags(Stitcher self, int val) {
    (CVDEREF(self))->setInterpolationFlags(static_cast<cv::InterpolationFlags>(val));
}

int cv_Stitcher_get_waveCorrectKind(Stitcher self) {
    return (CVDEREF(self))->waveCorrectKind();
}
void cv_Stitcher_set_waveCorrectKind(Stitcher self, int val) {
    (CVDEREF(self))->setWaveCorrectKind(static_cast<cv::detail::WaveCorrectKind>(val));
}

double cv_Stitcher_get_workScale(Stitcher self) {
    return (CVDEREF(self))->workScale();
}

CvStatus* cv_Stitcher_get_warper(Stitcher self, WarperCreator* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::WarperCreator>((CVDEREF(self))->warper());
    END_WRAP
}

CvStatus* cv_Stitcher_set_warper(Stitcher self, WarperCreator warper) {
    BEGIN_WRAP
    (CVDEREF(self))->setWarper(CVDEREF(warper));
    END_WRAP
}

CvStatus* cv_Stitcher_estimateTransform(
    Stitcher self, VecMat mats, VecMat masks, int* rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    if (!masks.ptr->empty()) {
        *rval = static_cast<int>((CVDEREF(self))->estimateTransform(CVDEREF(mats), CVDEREF(masks)));
    } else {
        *rval = static_cast<int>((CVDEREF(self))->estimateTransform(CVDEREF(mats)));
    }
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_Stitcher_setTransform(
    Stitcher self,
    VecMat mats,
    VecCameraParams cameras,
    VecI32 component,
    int* rval,
    CvCallback_0 callback
) {
    BEGIN_WRAP
    if (component.ptr->empty()) {
        *rval = static_cast<int>((CVDEREF(self))->setTransform(CVDEREF(mats), CVDEREF(cameras)));
    } else {
        const std::vector<int> _component(component.ptr->begin(), component.ptr->end());
        *rval = static_cast<int>(
            (CVDEREF(self))->setTransform(CVDEREF(mats), CVDEREF(cameras), _component)
        );
    }
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_Stitcher_composePanorama(Stitcher self, Mat rpano, int* rval, CvCallback_0 callback) {
    BEGIN_WRAP
    *rval = static_cast<int>((CVDEREF(self))->composePanorama(CVDEREF(rpano)));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}
CvStatus* cv_Stitcher_composePanorama_1(
    Stitcher self, VecMat mats, Mat rpano, int* rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    *rval = static_cast<int>((CVDEREF(self))->composePanorama(CVDEREF(mats), CVDEREF(rpano)));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_Stitcher_stitch(
    Stitcher self, VecMat mats, Mat rpano, int* rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    *rval = static_cast<int>((CVDEREF(self))->stitch(CVDEREF(mats), CVDEREF(rpano)));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}
CvStatus* cv_Stitcher_stitch_1(
    Stitcher self, VecMat mats, VecMat masks, Mat rpano, int* rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    *rval = static_cast<int>((CVDEREF(self))->stitch(CVDEREF(mats), CVDEREF(masks), CVDEREF(rpano)));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_Stitcher_component(Stitcher self, VecI32* rval, CvCallback_0 callback) {
    BEGIN_WRAP
    std::vector<int> _rval = (CVDEREF(self))->component();
    *rval = {new std::vector<int32_t>(_rval)};
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_Stitcher_cameras(Stitcher self, VecCameraParams* rval, CvCallback_0 callback) {
    BEGIN_WRAP
    // Assign into the vector `rval` already owns; allocating a new one here would
    // leak the one cv_VecCameraParams_new made.
    *rval->ptr = (CVDEREF(self))->cameras();
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_Stitcher_resultMask(Stitcher self, Mat rmask, CvCallback_0 callback) {
    BEGIN_WRAP
    const cv::UMat mask = (CVDEREF(self))->resultMask();
    mask.copyTo(CVDEREF(rmask));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

#pragma region WarperCreator

CvStatus* cv_WarperCreator_create(int type, float a, float b, WarperCreator* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::WarperCreator>(makeWarperCreator(type, a, b));
    END_WRAP
}

void cv_WarperCreator_close(WarperCreatorPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

CvStatus* cv_WarperCreator_createWarper(WarperCreator self, float scale, RotationWarper* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::RotationWarper>((CVDEREF(self))->create(scale));
    END_WRAP
}
#pragma endregion

#pragma region RotationWarper

CvStatus* cv_RotationWarper_create(int type, float a, float b, float scale, RotationWarper* rval) {
    BEGIN_WRAP
    const auto creator = makeWarperCreator(type, a, b);
    rval->ptr = new cv::Ptr<cv::detail::RotationWarper>(creator->create(scale));
    END_WRAP
}

void cv_RotationWarper_close(RotationWarperPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

float cv_RotationWarper_get_scale(RotationWarper self) {
    return (CVDEREF(self))->getScale();
}

void cv_RotationWarper_set_scale(RotationWarper self, float val) {
    (CVDEREF(self))->setScale(val);
}

CvStatus* cv_RotationWarper_warpPoint(
    RotationWarper self, CvPoint2f pt, Mat K, Mat R, CvPoint2f* rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    const cv::Point2f p =
        (CVDEREF(self))->warpPoint(cv::Point2f(pt.x, pt.y), CVDEREF(K), CVDEREF(R));
    *rval = {p.x, p.y};
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_RotationWarper_warpPointBackward(
    RotationWarper self, CvPoint2f pt, Mat K, Mat R, CvPoint2f* rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    const cv::Point2f p =
        (CVDEREF(self))->warpPointBackward(cv::Point2f(pt.x, pt.y), CVDEREF(K), CVDEREF(R));
    *rval = {p.x, p.y};
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_RotationWarper_buildMaps(
    RotationWarper self,
    CvSize src_size,
    Mat K,
    Mat R,
    Mat xmap,
    Mat ymap,
    CvRect* rval,
    CvCallback_0 callback
) {
    BEGIN_WRAP
    const cv::Rect r = (CVDEREF(self))
                           ->buildMaps(
                               cv::Size(src_size.width, src_size.height),
                               CVDEREF(K),
                               CVDEREF(R),
                               CVDEREF(xmap),
                               CVDEREF(ymap)
                           );
    *rval = {r.x, r.y, r.width, r.height};
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

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
) {
    BEGIN_WRAP
    const cv::Point p = (CVDEREF(self))
                            ->warp(
                                CVDEREF(src),
                                CVDEREF(K),
                                CVDEREF(R),
                                interp_mode,
                                border_mode,
                                CVDEREF(dst)
                            );
    *rval = {p.x, p.y};
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

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
) {
    BEGIN_WRAP
    (CVDEREF(self))
        ->warpBackward(
            CVDEREF(src),
            CVDEREF(K),
            CVDEREF(R),
            interp_mode,
            border_mode,
            cv::Size(dst_size.width, dst_size.height),
            CVDEREF(dst)
        );
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_RotationWarper_warpRoi(
    RotationWarper self, CvSize src_size, Mat K, Mat R, CvRect* rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    const cv::Rect r =
        (CVDEREF(self))
            ->warpRoi(cv::Size(src_size.width, src_size.height), CVDEREF(K), CVDEREF(R));
    *rval = {r.x, r.y, r.width, r.height};
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}
#pragma endregion

#pragma region VecCameraParams

VecCameraParams* cv_VecCameraParams_new(size_t length) {
    return new VecCameraParams{new std::vector<cv::detail::CameraParams>(length)};
}

void cv_VecCameraParams_close(VecCameraParamsPtr self) {
    delete self->ptr;
    delete self;
}

size_t cv_VecCameraParams_length(VecCameraParams self) {
    return self.ptr->size();
}

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
) {
    BEGIN_WRAP
    const auto& camera = self.ptr->at(index);
    *focal = camera.focal;
    *aspect = camera.aspect;
    *ppx = camera.ppx;
    *ppy = camera.ppy;
    camera.R.copyTo(CVDEREF(R));
    camera.t.copyTo(CVDEREF(t));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

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
) {
    BEGIN_WRAP
    auto& camera = self.ptr->at(index);
    camera.focal = focal;
    camera.aspect = aspect;
    camera.ppx = ppx;
    camera.ppy = ppy;
    camera.R = CVDEREF(R).clone();
    camera.t = CVDEREF(t).clone();
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}
#pragma endregion

#pragma region pipeline components

// --- features finder ---

CvStatus* cv_FeaturesFinder_create(int type, int nfeatures, FeaturesFinder* rval) {
    BEGIN_WRAP
    cv::Ptr<cv::Feature2D> finder;
    switch (type) {
        case STITCHING_FINDER_ORB:
            finder = nfeatures > 0 ? cv::ORB::create(nfeatures) : cv::ORB::create();
            break;
        case STITCHING_FINDER_SIFT:
            finder = cv::SIFT::create(nfeatures > 0 ? nfeatures : 0);
            break;
        case STITCHING_FINDER_AKAZE:
            finder = cv::AKAZE::create(
                cv::AKAZE::DESCRIPTOR_MLDB,
                0,
                3,
                0.001f,
                4,
                4,
                cv::KAZE::DIFF_PM_G2,
                nfeatures > 0 ? nfeatures : -1
            );
            break;
        case STITCHING_FINDER_BRISK:
            finder = cv::BRISK::create();
            break;
        default:
            CV_Error(cv::Error::StsBadArg, cv::format("unknown features finder type: %d", type));
    }
    rval->ptr = new cv::Ptr<cv::Feature2D>(finder);
    END_WRAP
}

void cv_FeaturesFinder_close(FeaturesFinderPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

CvStatus* cv_Stitcher_get_featuresFinder(Stitcher self, FeaturesFinder* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::Feature2D>((CVDEREF(self))->featuresFinder());
    END_WRAP
}

CvStatus* cv_Stitcher_set_featuresFinder(Stitcher self, FeaturesFinder finder) {
    BEGIN_WRAP
    (CVDEREF(self))->setFeaturesFinder(CVDEREF(finder));
    END_WRAP
}

// --- features matcher ---

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
) {
    BEGIN_WRAP
    cv::Ptr<cv::detail::FeaturesMatcher> matcher;
    switch (type) {
        case STITCHING_MATCHER_BEST_OF_2_NEAREST:
            matcher = cv::makePtr<cv::detail::BestOf2NearestMatcher>(
                try_use_gpu,
                match_conf,
                num_matches_thresh1,
                num_matches_thresh2,
                matches_confidence_thresh
            );
            break;
        case STITCHING_MATCHER_BEST_OF_2_NEAREST_RANGE:
            matcher = cv::makePtr<cv::detail::BestOf2NearestRangeMatcher>(
                range_width, try_use_gpu, match_conf, num_matches_thresh1, num_matches_thresh2
            );
            break;
        case STITCHING_MATCHER_AFFINE_BEST_OF_2_NEAREST:
            matcher = cv::makePtr<cv::detail::AffineBestOf2NearestMatcher>(
                full_affine, try_use_gpu, match_conf, num_matches_thresh1
            );
            break;
        default:
            CV_Error(cv::Error::StsBadArg, cv::format("unknown features matcher type: %d", type));
    }
    rval->ptr = new cv::Ptr<cv::detail::FeaturesMatcher>(matcher);
    END_WRAP
}

void cv_FeaturesMatcher_close(FeaturesMatcherPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

bool cv_FeaturesMatcher_isThreadSafe(FeaturesMatcher self) {
    return (CVDEREF(self))->isThreadSafe();
}

CvStatus* cv_FeaturesMatcher_collectGarbage(FeaturesMatcher self) {
    BEGIN_WRAP
    (CVDEREF(self))->collectGarbage();
    END_WRAP
}

CvStatus* cv_Stitcher_get_featuresMatcher(Stitcher self, FeaturesMatcher* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::FeaturesMatcher>((CVDEREF(self))->featuresMatcher());
    END_WRAP
}

CvStatus* cv_Stitcher_set_featuresMatcher(Stitcher self, FeaturesMatcher matcher) {
    BEGIN_WRAP
    (CVDEREF(self))->setFeaturesMatcher(CVDEREF(matcher));
    END_WRAP
}

CvStatus* cv_Stitcher_get_matchingMask(Stitcher self, Mat rval, CvCallback_0 callback) {
    BEGIN_WRAP
    (CVDEREF(self))->matchingMask().copyTo(CVDEREF(rval));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_Stitcher_set_matchingMask(Stitcher self, Mat mask) {
    BEGIN_WRAP
    (CVDEREF(self))->setMatchingMask(CVDEREF(mask).getUMat(cv::ACCESS_READ));
    END_WRAP
}

// --- estimator ---

CvStatus* cv_Estimator_create(int type, bool is_focals_estimated, Estimator* rval) {
    BEGIN_WRAP
    cv::Ptr<cv::detail::Estimator> estimator;
    switch (type) {
        case STITCHING_ESTIMATOR_HOMOGRAPHY:
            estimator = cv::makePtr<cv::detail::HomographyBasedEstimator>(is_focals_estimated);
            break;
        case STITCHING_ESTIMATOR_AFFINE:
            estimator = cv::makePtr<cv::detail::AffineBasedEstimator>();
            break;
        default:
            CV_Error(cv::Error::StsBadArg, cv::format("unknown estimator type: %d", type));
    }
    rval->ptr = new cv::Ptr<cv::detail::Estimator>(estimator);
    END_WRAP
}

void cv_Estimator_close(EstimatorPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

CvStatus* cv_Stitcher_get_estimator(Stitcher self, Estimator* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::Estimator>((CVDEREF(self))->estimator());
    END_WRAP
}

CvStatus* cv_Stitcher_set_estimator(Stitcher self, Estimator estimator) {
    BEGIN_WRAP
    (CVDEREF(self))->setEstimator(CVDEREF(estimator));
    END_WRAP
}

// --- bundle adjuster ---

CvStatus* cv_BundleAdjuster_create(int type, BundleAdjuster* rval) {
    BEGIN_WRAP
    cv::Ptr<cv::detail::BundleAdjusterBase> adjuster;
    switch (type) {
        case STITCHING_BUNDLE_ADJUSTER_NO:
            adjuster = cv::makePtr<cv::detail::NoBundleAdjuster>();
            break;
        case STITCHING_BUNDLE_ADJUSTER_REPROJ:
            adjuster = cv::makePtr<cv::detail::BundleAdjusterReproj>();
            break;
        case STITCHING_BUNDLE_ADJUSTER_RAY:
            adjuster = cv::makePtr<cv::detail::BundleAdjusterRay>();
            break;
        case STITCHING_BUNDLE_ADJUSTER_AFFINE:
            adjuster = cv::makePtr<cv::detail::BundleAdjusterAffine>();
            break;
        case STITCHING_BUNDLE_ADJUSTER_AFFINE_PARTIAL:
            adjuster = cv::makePtr<cv::detail::BundleAdjusterAffinePartial>();
            break;
        default:
            CV_Error(cv::Error::StsBadArg, cv::format("unknown bundle adjuster type: %d", type));
    }
    rval->ptr = new cv::Ptr<cv::detail::BundleAdjusterBase>(adjuster);
    END_WRAP
}

void cv_BundleAdjuster_close(BundleAdjusterPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

double cv_BundleAdjuster_get_confThresh(BundleAdjuster self) {
    return (CVDEREF(self))->confThresh();
}

void cv_BundleAdjuster_set_confThresh(BundleAdjuster self, double val) {
    (CVDEREF(self))->setConfThresh(val);
}

CvStatus* cv_BundleAdjuster_get_refinementMask(
    BundleAdjuster self, Mat rval, CvCallback_0 callback
) {
    BEGIN_WRAP
    (CVDEREF(self))->refinementMask().copyTo(CVDEREF(rval));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_BundleAdjuster_set_refinementMask(BundleAdjuster self, Mat mask) {
    BEGIN_WRAP
    (CVDEREF(self))->setRefinementMask(CVDEREF(mask));
    END_WRAP
}

TermCriteria cv_BundleAdjuster_get_termCriteria(BundleAdjuster self) {
    const cv::TermCriteria tc = (CVDEREF(self))->termCriteria();
    return {tc.type, tc.maxCount, tc.epsilon};
}

void cv_BundleAdjuster_set_termCriteria(BundleAdjuster self, TermCriteria val) {
    (CVDEREF(self))->setTermCriteria(cv::TermCriteria(val.type, val.maxCount, val.epsilon));
}

CvStatus* cv_Stitcher_get_bundleAdjuster(Stitcher self, BundleAdjuster* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::BundleAdjusterBase>((CVDEREF(self))->bundleAdjuster());
    END_WRAP
}

CvStatus* cv_Stitcher_set_bundleAdjuster(Stitcher self, BundleAdjuster adjuster) {
    BEGIN_WRAP
    (CVDEREF(self))->setBundleAdjuster(CVDEREF(adjuster));
    END_WRAP
}

// --- exposure compensator ---

CvStatus* cv_ExposureCompensator_create(int type, ExposureCompensator* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::ExposureCompensator>(
        cv::detail::ExposureCompensator::createDefault(type)
    );
    END_WRAP
}

void cv_ExposureCompensator_close(ExposureCompensatorPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

bool cv_ExposureCompensator_get_updateGain(ExposureCompensator self) {
    return (CVDEREF(self))->getUpdateGain();
}

void cv_ExposureCompensator_set_updateGain(ExposureCompensator self, bool val) {
    (CVDEREF(self))->setUpdateGain(val);
}

CvStatus* cv_ExposureCompensator_get_blockSize(ExposureCompensator self, CvSize* rval) {
    BEGIN_WRAP
    const cv::Size sz =
        downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "block size").getBlockSize();
    *rval = {sz.width, sz.height};
    END_WRAP
}

CvStatus* cv_ExposureCompensator_set_blockSize(ExposureCompensator self, CvSize val) {
    BEGIN_WRAP
    downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "block size")
        .setBlockSize(val.width, val.height);
    END_WRAP
}

CvStatus* cv_ExposureCompensator_get_nrFeeds(ExposureCompensator self, int* rval) {
    BEGIN_WRAP
    *rval = downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "feed count").getNrFeeds();
    END_WRAP
}

CvStatus* cv_ExposureCompensator_set_nrFeeds(ExposureCompensator self, int val) {
    BEGIN_WRAP
    downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "feed count").setNrFeeds(val);
    END_WRAP
}

CvStatus* cv_ExposureCompensator_get_nrGainsFilteringIterations(
    ExposureCompensator self, int* rval
) {
    BEGIN_WRAP
    *rval = downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "gain filtering")
                .getNrGainsFilteringIterations();
    END_WRAP
}

CvStatus* cv_ExposureCompensator_set_nrGainsFilteringIterations(ExposureCompensator self, int val) {
    BEGIN_WRAP
    downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "gain filtering")
        .setNrGainsFilteringIterations(val);
    END_WRAP
}

CvStatus* cv_ExposureCompensator_get_similarityThreshold(ExposureCompensator self, double* rval) {
    BEGIN_WRAP
    *rval = downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "similarity threshold")
                .getSimilarityThreshold();
    END_WRAP
}

CvStatus* cv_ExposureCompensator_set_similarityThreshold(ExposureCompensator self, double val) {
    BEGIN_WRAP
    downcastOrThrow<cv::detail::BlocksCompensator>(CVDEREF(self), "similarity threshold")
        .setSimilarityThreshold(val);
    END_WRAP
}

CvStatus* cv_Stitcher_get_exposureCompensator(Stitcher self, ExposureCompensator* rval) {
    BEGIN_WRAP
    rval->ptr =
        new cv::Ptr<cv::detail::ExposureCompensator>((CVDEREF(self))->exposureCompensator());
    END_WRAP
}

CvStatus* cv_Stitcher_set_exposureCompensator(
    Stitcher self, ExposureCompensator compensator
) {
    BEGIN_WRAP
    (CVDEREF(self))->setExposureCompensator(CVDEREF(compensator));
    END_WRAP
}

// --- seam finder ---

CvStatus* cv_SeamFinder_create(
    int type, float terminal_cost, float bad_region_penalty, SeamFinder* rval
) {
    BEGIN_WRAP
    cv::Ptr<cv::detail::SeamFinder> finder;
    switch (type) {
        case STITCHING_SEAM_NO:
            finder = cv::makePtr<cv::detail::NoSeamFinder>();
            break;
        case STITCHING_SEAM_VORONOI:
            finder = cv::makePtr<cv::detail::VoronoiSeamFinder>();
            break;
        case STITCHING_SEAM_DP_COLOR:
            finder = cv::makePtr<cv::detail::DpSeamFinder>(cv::detail::DpSeamFinder::COLOR);
            break;
        case STITCHING_SEAM_DP_COLOR_GRAD:
            finder = cv::makePtr<cv::detail::DpSeamFinder>(cv::detail::DpSeamFinder::COLOR_GRAD);
            break;
        case STITCHING_SEAM_GRAPH_CUT_COLOR:
            finder = cv::makePtr<cv::detail::GraphCutSeamFinder>(
                cv::detail::GraphCutSeamFinderBase::COST_COLOR, terminal_cost, bad_region_penalty
            );
            break;
        case STITCHING_SEAM_GRAPH_CUT_COLOR_GRAD:
            finder = cv::makePtr<cv::detail::GraphCutSeamFinder>(
                cv::detail::GraphCutSeamFinderBase::COST_COLOR_GRAD,
                terminal_cost,
                bad_region_penalty
            );
            break;
        default:
            CV_Error(cv::Error::StsBadArg, cv::format("unknown seam finder type: %d", type));
    }
    rval->ptr = new cv::Ptr<cv::detail::SeamFinder>(finder);
    END_WRAP
}

void cv_SeamFinder_close(SeamFinderPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

CvStatus* cv_Stitcher_get_seamFinder(Stitcher self, SeamFinder* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::SeamFinder>((CVDEREF(self))->seamFinder());
    END_WRAP
}

CvStatus* cv_Stitcher_set_seamFinder(Stitcher self, SeamFinder finder) {
    BEGIN_WRAP
    (CVDEREF(self))->setSeamFinder(CVDEREF(finder));
    END_WRAP
}

// --- blender ---

CvStatus* cv_Blender_create(int type, bool try_gpu, Blender* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::Blender>(cv::detail::Blender::createDefault(type, try_gpu));
    END_WRAP
}

void cv_Blender_close(BlenderPtr self) {
    self->ptr->reset();
    CVD_FREE(self);
}

CvStatus* cv_Blender_get_sharpness(Blender self, float* rval) {
    BEGIN_WRAP
    *rval = downcastOrThrow<cv::detail::FeatherBlender>(CVDEREF(self), "sharpness").sharpness();
    END_WRAP
}

CvStatus* cv_Blender_set_sharpness(Blender self, float val) {
    BEGIN_WRAP
    downcastOrThrow<cv::detail::FeatherBlender>(CVDEREF(self), "sharpness").setSharpness(val);
    END_WRAP
}

CvStatus* cv_Blender_get_numBands(Blender self, int* rval) {
    BEGIN_WRAP
    *rval = downcastOrThrow<cv::detail::MultiBandBlender>(CVDEREF(self), "band count").numBands();
    END_WRAP
}

CvStatus* cv_Blender_set_numBands(Blender self, int val) {
    BEGIN_WRAP
    downcastOrThrow<cv::detail::MultiBandBlender>(CVDEREF(self), "band count").setNumBands(val);
    END_WRAP
}

CvStatus* cv_Stitcher_get_blender(Stitcher self, Blender* rval) {
    BEGIN_WRAP
    rval->ptr = new cv::Ptr<cv::detail::Blender>((CVDEREF(self))->blender());
    END_WRAP
}

CvStatus* cv_Stitcher_set_blender(Stitcher self, Blender blender) {
    BEGIN_WRAP
    (CVDEREF(self))->setBlender(CVDEREF(blender));
    END_WRAP
}
#pragma endregion

#pragma region rotation estimation

CvStatus* cv_detail_waveCorrect(VecMat rmats, int kind, CvCallback_0 callback) {
    BEGIN_WRAP
    cv::detail::waveCorrect(CVDEREF(rmats), static_cast<cv::detail::WaveCorrectKind>(kind));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}

CvStatus* cv_detail_autoDetectWaveCorrectKind(VecMat rmats, int* rval, CvCallback_0 callback) {
    BEGIN_WRAP
    *rval = static_cast<int>(cv::detail::autoDetectWaveCorrectKind(CVDEREF(rmats)));
    if (callback != nullptr) {
        callback();
    }
    END_WRAP
}
#pragma endregion
