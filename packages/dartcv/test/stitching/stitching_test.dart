import 'package:dartcv4/dartcv.dart' as cv;
import 'package:test/test.dart';

void main() {
  test('cv.Stitcher', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    final (status, pano) = stitcher.stitch(images.cvd);
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
    // cv.imwrite('test/images_out/stitcher_test.jpg', pano);

    stitcher.dispose();
  });

  test('cv.Stitcher with mask', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];

    final masks = [
      cv.imread("test/images/barcode_mask1.png", flags: cv.IMREAD_GRAYSCALE),
      cv.imread("test/images/barcode_mask2.png", flags: cv.IMREAD_GRAYSCALE),
    ];
    final (status, pano) = stitcher.stitch(images.cvd, masks: masks.cvd);
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
    // cv.imwrite('test/images_out/stitcher_test_mask.jpg', pano);
  });

  test('cv.Stitcher getter/setter', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    stitcher.registrationResol = 3.14159;
    expect(stitcher.registrationResol, 3.14159);

    stitcher.seamEstimationResol = 3.14159;
    expect(stitcher.seamEstimationResol, 3.14159);

    stitcher.panoConfidenceThresh = 3.14159;
    expect(stitcher.panoConfidenceThresh, 3.14159);

    stitcher.compositingResol = 3.14159;
    expect(stitcher.compositingResol, 3.14159);

    stitcher.waveCorrection = true;
    expect(stitcher.waveCorrection, true);

    stitcher.waveCorrectKind = cv.WaveCorrectKind.HORIZONTAL.index;
    expect(stitcher.waveCorrectKind, cv.WaveCorrectKind.HORIZONTAL.index);

    stitcher.interpolationFlags = cv.INTER_LINEAR;
    expect(stitcher.interpolationFlags, cv.INTER_LINEAR);

    expect(stitcher.component.length, greaterThanOrEqualTo(0));
  });

  test('Issue 48', () {
    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];

    // Create Stitcher object
    final cv.Stitcher stitcher = cv.Stitcher.create();

    // Estimate transformations and stitch images
    final cv.StitcherStatus status = stitcher.estimateTransform(images.cvd);
    expect(status, cv.StitcherStatus.OK);

    final result = stitcher.composePanorama();
    expect(result.$1, cv.StitcherStatus.OK);
    expect(result.$2.isEmpty, false);

    final result1 = stitcher.composePanorama(images: images.cvd);
    expect(result1.$1, cv.StitcherStatus.OK);
    expect(result1.$2.isEmpty, false);
  });

  test('cv.WarperCreator', () {
    for (final type in cv.WarperType.values) {
      final creator = cv.WarperCreator(type);
      addTearDown(creator.dispose);

      final warper = creator.createWarper(500);
      addTearDown(warper.dispose);
      expect(warper.isDisposed, false);
    }
  });

  test('cv.WarperCreator parametric', () {
    // a/b reach the projection only for the parametric warpers; the rest ignore
    // them, so passing values there must still succeed.
    expect(cv.WarperType.panini.isParametric, true);
    expect(cv.WarperType.cylindrical.isParametric, false);

    final panini = cv.WarperCreator(cv.WarperType.panini, a: 2, b: 1);
    expect(panini.createWarper(300).scale, 300);

    final cylindrical = cv.WarperCreator(cv.WarperType.cylindrical, a: 2, b: 1);
    expect(cylindrical.createWarper(300).scale, 300);
  });

  test('cv.Stitcher.warper', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);

    // Every mode starts with a warper installed, so the getter works untouched.
    expect(stitcher.warper.isDisposed, false);

    stitcher.warper = cv.WarperCreator(cv.WarperType.cylindrical);

    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    final (status, pano) = stitcher.stitch(images.cvd);
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
  });

  test('cv.RotationWarper', () {
    final img = cv.imread("test/images/lenna.png", flags: cv.IMREAD_COLOR);
    const focal = 400.0;
    final K = cv.Mat.from2DList([
      [focal, 0.0, img.cols / 2],
      [0.0, focal, img.rows / 2],
      [0.0, 0.0, 1.0],
    ], cv.MatType.CV_32FC1);
    final R = cv.Mat.eye(3, 3, cv.MatType.CV_32FC1);

    final warper = cv.RotationWarper(cv.WarperType.cylindrical, focal);
    addTearDown(warper.dispose);
    expect(warper.scale, focal);

    final (corner, warped) = warper.warp(img, K, R);
    expect(warped.isEmpty, false);
    expect(warped.channels, img.channels);

    // warpRoi predicts the box warp actually produces.
    final roi = warper.warpRoi(cv.Size(img.cols, img.rows), K, R);
    expect(roi.x, corner.x);
    expect(roi.y, corner.y);
    expect(roi.width, warped.cols);
    expect(roi.height, warped.rows);

    // buildMaps reports the same box with inclusive corners, so it measures one
    // pixel short in each direction while the tables it writes match the image.
    final (mapRoi, xmap, ymap) = warper.buildMaps(cv.Size(img.cols, img.rows), K, R);
    expect(mapRoi.x, roi.x);
    expect(mapRoi.y, roi.y);
    expect(mapRoi.width, roi.width - 1);
    expect(mapRoi.height, roi.height - 1);
    expect(xmap.rows, roi.height);
    expect(xmap.cols, roi.width);
    expect(ymap.rows, roi.height);
    expect(ymap.cols, roi.width);

    final back = warper.warpBackward(warped, K, R, cv.Size(img.cols, img.rows));
    expect(back.rows, img.rows);
    expect(back.cols, img.cols);

    // With an identity rotation the principal point stays put under a
    // round trip through the cylinder.
    final centre = cv.Point2f(img.cols / 2, img.rows / 2);
    final projected = warper.warpPoint(centre, K, R);
    final restored = warper.warpPointBackward(projected, K, R);
    expect(restored.x, closeTo(centre.x, 1e-2));
    expect(restored.y, closeTo(centre.y, 1e-2));
  });

  test('cv.Stitcher.cameras', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);

    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    expect(stitcher.estimateTransform(images.cvd), cv.StitcherStatus.OK);

    expect(stitcher.workScale, greaterThan(0));

    final cameras = stitcher.cameras;
    expect(cameras.length, 2);
    for (final camera in cameras) {
      expect(camera.focal, greaterThan(0));
      expect(camera.aspect, greaterThan(0));
      // The pipeline converts rotations to CV_32F before handing them out.
      expect(camera.R.type, cv.MatType.CV_32FC1);
      expect((camera.R.rows, camera.R.cols), (3, 3));
      expect(camera.K.type, cv.MatType.CV_64FC1);
      expect(camera.K.at<double>(0, 0), closeTo(camera.focal, 1e-9));
      expect(camera.K.at<double>(1, 1), closeTo(camera.focal * camera.aspect, 1e-9));
    }

    final (status, pano) = stitcher.composePanorama();
    expect(status, cv.StitcherStatus.OK);

    final mask = stitcher.resultMask;
    expect(mask.isEmpty, false);
    expect(mask.type, cv.MatType.CV_8UC1);
    expect((mask.rows, mask.cols), (pano.rows, pano.cols));
  });

  test('cv.waveCorrect', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);
    // estimateTransform wave-corrects on its own when this is on; turn it off so
    // the correction below is the only one applied.
    stitcher.waveCorrection = false;

    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    expect(stitcher.estimateTransform(images.cvd), cv.StitcherStatus.OK);

    final cameras = stitcher.cameras;
    final before = cameras.map((c) => c.R.clone()).toList();
    final rmats = cameras.map((c) => c.R).toList().cvd;

    expect(cv.autoDetectWaveCorrectKind(rmats), isNot(cv.WaveCorrectKind.AUTO));

    cv.waveCorrect(rmats, cv.WaveCorrectKind.HORIZONTAL);
    expect(rmats.length, before.length);
    for (var i = 0; i < rmats.length; i++) {
      expect(rmats[i].type, cv.MatType.CV_32FC1);
      expect((rmats[i].rows, rmats[i].cols), (3, 3));
    }

    for (var i = 0; i < cameras.length; i++) {
      cameras[i].R = rmats[i];
    }
    expect(stitcher.setTransform(images.cvd, cameras), cv.StitcherStatus.OK);

    final (status, pano) = stitcher.composePanorama();
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
  });

  test('cv.waveCorrect AUTO and single rotation', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);
    stitcher.waveCorrection = false;

    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    expect(stitcher.estimateTransform(images.cvd), cv.StitcherStatus.OK);

    final cameras = stitcher.cameras;
    final auto = cameras.map((c) => c.R.clone()).toList().cvd;
    final detected = cv.autoDetectWaveCorrectKind(auto);
    final explicitly = cameras.map((c) => c.R.clone()).toList().cvd;

    cv.waveCorrect(auto, cv.WaveCorrectKind.AUTO);
    cv.waveCorrect(explicitly, detected);

    // AUTO resolves to what autoDetectWaveCorrectKind reports.
    for (var i = 0; i < auto.length; i++) {
      expect(cv.norm1(auto[i], explicitly[i], normType: cv.NORM_INF), closeTo(0, 1e-6));
    }

    // OpenCV leaves a lone rotation alone.
    final single = [cameras.first.R.clone()].cvd;
    final unchanged = single[0].clone();
    cv.waveCorrect(single, cv.WaveCorrectKind.HORIZONTAL);
    expect(cv.norm1(single[0], unchanged, normType: cv.NORM_INF), closeTo(0, 1e-9));
  });

  test('cv.Stitcher.setTransform with component', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);

    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    expect(stitcher.estimateTransform(images.cvd), cv.StitcherStatus.OK);

    final cameras = stitcher.cameras;
    final component = stitcher.component.toList();
    expect(stitcher.setTransform(images.cvd, cameras, component: component), cv.StitcherStatus.OK);

    final (status, pano) = stitcher.composePanorama();
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
  });

  test('cv.FeaturesFinder', () {
    for (final type in cv.FeaturesFinderType.values) {
      final finder = cv.FeaturesFinder(type, nfeatures: 400);
      addTearDown(finder.dispose);
      expect(finder.isDisposed, false);
    }
    expect(cv.FeaturesFinderType.brisk.supportsFeatureCap, false);
    expect(cv.FeaturesFinderType.orb.supportsFeatureCap, true);
  });

  test('cv.FeaturesMatcher', () {
    for (final type in cv.MatcherType.values) {
      final matcher = cv.FeaturesMatcher(type, rangeWidth: 2, fullAffine: true);
      addTearDown(matcher.dispose);
      matcher.collectGarbage();
      expect(matcher.isThreadSafe, isA<bool>());
    }
  });

  test('cv.Estimator / cv.BundleAdjuster', () {
    for (final type in cv.EstimatorType.values) {
      final estimator = cv.Estimator(type);
      addTearDown(estimator.dispose);
      expect(estimator.isDisposed, false);
    }

    for (final type in cv.BundleAdjusterType.values) {
      final adjuster = cv.BundleAdjuster(type);
      addTearDown(adjuster.dispose);

      adjuster.confThresh = 0.7;
      expect(adjuster.confThresh, closeTo(0.7, 1e-9));

      // OpenCV starts every adjuster refining all intrinsics.
      final defaultMask = adjuster.refinementMask;
      expect(defaultMask.type, cv.MatType.CV_8UC1);
      expect((defaultMask.rows, defaultMask.cols), (3, 3));

      // Pin everything but the focal length, as a fixed-lens rig wants.
      final mask = cv.Mat.zeros(3, 3, cv.MatType.CV_8UC1);
      mask.set<int>(0, 0, 1);
      adjuster.refinementMask = mask;
      final readBack = adjuster.refinementMask;
      expect(readBack.at<int>(0, 0), 1);
      expect(readBack.at<int>(1, 1), 0);
      expect(readBack.at<int>(0, 2), 0);

      adjuster.termCriteria = cv.TermCriteria(cv.TERM_EPS + cv.TERM_COUNT, 55, 1e-4);
      expect(adjuster.termCriteria.maxCount, 55);
      expect(adjuster.termCriteria.eps, closeTo(1e-4, 1e-12));
    }
  });

  test('cv.ExposureCompensator', () {
    for (final type in cv.ExposureCompensatorType.values) {
      final comp = cv.ExposureCompensator(type);
      addTearDown(comp.dispose);

      comp.updateGain = false;
      expect(comp.updateGain, false);

      if (type.isBlockBased) {
        comp.blockSize = cv.Size(16, 24);
        expect((comp.blockSize.width, comp.blockSize.height), (16, 24));

        comp.nrFeeds = 3;
        expect(comp.nrFeeds, 3);

        comp.nrGainsFilteringIterations = 4;
        expect(comp.nrGainsFilteringIterations, 4);

        comp.similarityThreshold = 1.5;
        expect(comp.similarityThreshold, closeTo(1.5, 1e-9));
      } else {
        // The block-only settings report a clear error rather than crashing.
        expect(() => comp.blockSize, throwsA(isA<cv.CvException>()));
        expect(() => comp.nrFeeds, throwsA(isA<cv.CvException>()));
      }
    }
  });

  test('cv.SeamFinder / cv.Blender', () {
    for (final type in cv.SeamFinderType.values) {
      final finder = cv.SeamFinder(type);
      addTearDown(finder.dispose);
      expect(finder.isDisposed, false);
    }
    expect(cv.SeamFinderType.graphCutColorGrad.isGraphCut, true);
    expect(cv.SeamFinderType.voronoi.isGraphCut, false);

    final feather = cv.Blender(cv.BlenderType.feather);
    addTearDown(feather.dispose);
    feather.sharpness = 0.05;
    expect(feather.sharpness, closeTo(0.05, 1e-6));
    expect(() => feather.numBands, throwsA(isA<cv.CvException>()));

    final multiBand = cv.Blender(cv.BlenderType.multiBand);
    addTearDown(multiBand.dispose);
    multiBand.numBands = 3;
    expect(multiBand.numBands, 3);
    expect(() => multiBand.sharpness, throwsA(isA<cv.CvException>()));
  });

  test('cv.sequentialMatchingMask', () {
    final mask = cv.sequentialMatchingMask(5, range: 1);
    expect(mask.type, cv.MatType.CV_8UC1);
    expect((mask.rows, mask.cols), (5, 5));

    // Neighbours on, symmetric, diagonal clear.
    expect(mask.at<int>(0, 1), 1);
    expect(mask.at<int>(1, 0), 1);
    expect(mask.at<int>(0, 2), 0);
    for (var i = 0; i < 5; i++) {
      expect(mask.at<int>(i, i), 0);
    }
    // range 1 with loop closes the revolution: last frame meets the first.
    expect(mask.at<int>(4, 0), 1);
    expect(mask.at<int>(0, 4), 1);

    final open = cv.sequentialMatchingMask(5, range: 1, loop: false);
    expect(open.at<int>(4, 0), 0);

    final wide = cv.sequentialMatchingMask(4, range: 2);
    expect(wide.at<int>(0, 2), 1);
    for (var i = 0; i < 4; i++) {
      expect(wide.at<int>(i, i), 0);
    }

    expect(() => cv.sequentialMatchingMask(-1), throwsArgumentError);
    expect(() => cv.sequentialMatchingMask(4, range: 0), throwsArgumentError);
  });

  test('cv.Stitcher pipeline round trip', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);

    // Every stage starts populated, so each getter works before any setter.
    expect(stitcher.featuresFinder.isDisposed, false);
    expect(stitcher.featuresMatcher.isDisposed, false);
    expect(stitcher.estimator.isDisposed, false);
    expect(stitcher.bundleAdjuster.isDisposed, false);
    expect(stitcher.exposureCompensator.isDisposed, false);
    expect(stitcher.seamFinder.isDisposed, false);
    expect(stitcher.blender.isDisposed, false);
    expect(stitcher.matchingMask.isEmpty, true);

    stitcher.featuresFinder = cv.FeaturesFinder(cv.FeaturesFinderType.sift);
    stitcher.featuresMatcher = cv.FeaturesMatcher(cv.MatcherType.bestOf2NearestRange, rangeWidth: 2);
    stitcher.estimator = cv.Estimator(cv.EstimatorType.homography);
    stitcher.bundleAdjuster = cv.BundleAdjuster(cv.BundleAdjusterType.ray);
    stitcher.exposureCompensator = cv.ExposureCompensator(cv.ExposureCompensatorType.gainBlocks);
    stitcher.seamFinder = cv.SeamFinder(cv.SeamFinderType.dpColorGrad);
    stitcher.blender = cv.Blender(cv.BlenderType.multiBand);
    stitcher.matchingMask = cv.sequentialMatchingMask(2, range: 1);

    // The blender read back is the one just installed, not the default.
    expect(stitcher.blender.numBands, isA<int>());
    expect(stitcher.exposureCompensator.blockSize.width, greaterThan(0));
    expect((stitcher.matchingMask.rows, stitcher.matchingMask.cols), (2, 2));
  });

  test('cv.Stitcher stitches with a fully rebuilt pipeline', () {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);

    stitcher.warper = cv.WarperCreator(cv.WarperType.cylindrical);
    stitcher.waveCorrection = false;
    stitcher.featuresFinder = cv.FeaturesFinder(cv.FeaturesFinderType.orb, nfeatures: 1500);
    stitcher.featuresMatcher = cv.FeaturesMatcher(cv.MatcherType.bestOf2NearestRange, rangeWidth: 1);
    stitcher.bundleAdjuster = cv.BundleAdjuster(cv.BundleAdjusterType.ray);
    stitcher.exposureCompensator = cv.ExposureCompensator(cv.ExposureCompensatorType.gainBlocks);
    stitcher.seamFinder = cv.SeamFinder(cv.SeamFinderType.dpColorGrad);
    stitcher.blender = cv.Blender(cv.BlenderType.multiBand)..numBands = 3;

    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    final (status, pano) = stitcher.stitch(images.cvd);
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
  });

  test('cv.FeaturesMatcher matchesConfidenceThresh gates dense detectors', () {
    // SIFT finds ~10k keypoints on these fixtures and matches them almost
    // perfectly, which pushes OpenCV's pair confidence — inliers / (8 + 0.3 *
    // matches), asymptotically 3.33 — past the default 3.0 guard meant to reject
    // near-duplicate frames. The overlapping pair is then thrown away.
    cv.StitcherStatus stitchWith(double thresh) {
      final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
      addTearDown(stitcher.dispose);
      stitcher.featuresFinder = cv.FeaturesFinder(cv.FeaturesFinderType.sift);
      stitcher.featuresMatcher = cv.FeaturesMatcher(
        cv.MatcherType.bestOf2Nearest,
        matchesConfidenceThresh: thresh,
      );
      final images = [
        cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
        cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
      ];
      return stitcher.stitch(images.cvd).$1;
    }

    expect(stitchWith(3), cv.StitcherStatus.ERR_NEED_MORE_IMGS);
    expect(stitchWith(10), cv.StitcherStatus.OK);
  });

  test('a Stitcher per stitch survives varying image counts', () {
    // cv::Stitcher never clears pairwise_matches_ on the stitch() path, and
    // MatcherType.bestOf2NearestRange refills only neighbouring pairs, so
    // reusing one stitcher leaks the previous stitch's matches into the next
    // one and can end in a -215 from invert. A stitcher per stitch is the
    // documented way round it — see MatcherType.bestOf2NearestRange.
    final images = [
      cv.imread("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      cv.imread("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];

    for (var round = 0; round < 3; round++) {
      final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
      addTearDown(stitcher.dispose);
      stitcher.featuresMatcher = cv.FeaturesMatcher(cv.MatcherType.bestOf2NearestRange, rangeWidth: 2);
      final (status, pano) = stitcher.stitch(images.cvd);
      expect(status, cv.StitcherStatus.OK, reason: 'round $round');
      expect(pano.isEmpty, false, reason: 'round $round');
    }
  });
}
