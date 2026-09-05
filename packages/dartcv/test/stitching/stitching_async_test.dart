import 'package:dartcv4/dartcv.dart' as cv;
import 'package:test/test.dart';

void main() {
  test('cv.StitcherAsync', () async {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    final images = [
      await cv.imreadAsync("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      await cv.imreadAsync("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    final (status, pano) = await stitcher.stitchAsync(images.cvd);
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
    stitcher.dispose();
  });

  test('cv.StitcherAsync with mask', () async {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    final images = [
      await cv.imreadAsync("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      await cv.imreadAsync("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];

    final masks = [
      await cv.imreadAsync("test/images/barcode_mask1.png", flags: cv.IMREAD_GRAYSCALE),
      await cv.imreadAsync("test/images/barcode_mask2.png", flags: cv.IMREAD_GRAYSCALE),
    ];
    final (status, pano) = await stitcher.stitchAsync(images.cvd, masks: masks.cvd);
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
    stitcher.dispose();
  });

  test('Issue 48', () async {
    final images = [
      await cv.imreadAsync("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      await cv.imreadAsync("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];

    final stitcher = cv.Stitcher.create();
    final status = await stitcher.estimateTransformAsync(images.cvd);
    expect(status, cv.StitcherStatus.OK);

    final result = await stitcher.composePanoramaAsync();
    expect(result.$1, cv.StitcherStatus.OK);
    expect(result.$2.isEmpty, false);

    final result1 = await stitcher.composePanoramaAsync(images: images.cvd);
    expect(result1.$1, cv.StitcherStatus.OK);
    expect(result1.$2.isEmpty, false);
  });

  test('cv.StitcherAsync cameras/setTransform/resultMask', () async {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);

    final images = [
      await cv.imreadAsync("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      await cv.imreadAsync("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    expect(await stitcher.estimateTransformAsync(images.cvd), cv.StitcherStatus.OK);

    final cameras = await stitcher.camerasAsync();
    expect(cameras.length, 2);
    expect(cameras.first.focal, greaterThan(0));

    expect(await stitcher.setTransformAsync(images.cvd, cameras), cv.StitcherStatus.OK);

    final (status, pano) = await stitcher.composePanoramaAsync();
    expect(status, cv.StitcherStatus.OK);

    final mask = await stitcher.resultMaskAsync();
    expect((mask.rows, mask.cols), (pano.rows, pano.cols));
  });

  test('cv.RotationWarperAsync', () async {
    final img = await cv.imreadAsync("test/images/lenna.png", flags: cv.IMREAD_COLOR);
    const focal = 400.0;
    final K = cv.Mat.from2DList([
      [focal, 0.0, img.cols / 2],
      [0.0, focal, img.rows / 2],
      [0.0, 0.0, 1.0],
    ], cv.MatType.CV_32FC1);
    final R = cv.Mat.eye(3, 3, cv.MatType.CV_32FC1);

    final warper = cv.RotationWarper(cv.WarperType.cylindrical, focal);
    addTearDown(warper.dispose);

    final (corner, warped) = await warper.warpAsync(img, K, R);
    expect(warped.isEmpty, false);

    final roi = await warper.warpRoiAsync(cv.Size(img.cols, img.rows), K, R);
    expect((roi.x, roi.y), (corner.x, corner.y));
    expect((roi.width, roi.height), (warped.cols, warped.rows));

    // buildMaps' rect uses inclusive corners; see the sync test.
    final (mapRoi, xmap, ymap) = await warper.buildMapsAsync(cv.Size(img.cols, img.rows), K, R);
    expect((mapRoi.width, mapRoi.height), (roi.width - 1, roi.height - 1));
    expect((xmap.rows, xmap.cols), (roi.height, roi.width));
    expect((ymap.rows, ymap.cols), (roi.height, roi.width));

    final back = await warper.warpBackwardAsync(warped, K, R, cv.Size(img.cols, img.rows));
    expect((back.rows, back.cols), (img.rows, img.cols));

    final centre = cv.Point2f(img.cols / 2, img.rows / 2);
    final projected = await warper.warpPointAsync(centre, K, R);
    final restored = await warper.warpPointBackwardAsync(projected, K, R);
    expect(restored.x, closeTo(centre.x, 1e-2));
    expect(restored.y, closeTo(centre.y, 1e-2));
  });

  test('cv.waveCorrectAsync', () async {
    final stitcher = cv.Stitcher.create(mode: cv.StitcherMode.PANORAMA);
    addTearDown(stitcher.dispose);
    stitcher.waveCorrection = false;

    final images = [
      await cv.imreadAsync("test/images/barcode1.png", flags: cv.IMREAD_COLOR),
      await cv.imreadAsync("test/images/barcode2.png", flags: cv.IMREAD_COLOR),
    ];
    expect(await stitcher.estimateTransformAsync(images.cvd), cv.StitcherStatus.OK);

    final cameras = await stitcher.camerasAsync();
    final rmats = cameras.map((c) => c.R).toList().cvd;

    expect(await cv.autoDetectWaveCorrectKindAsync(rmats), isNot(cv.WaveCorrectKind.AUTO));
    await cv.waveCorrectAsync(rmats, cv.WaveCorrectKind.HORIZONTAL);

    for (var i = 0; i < cameras.length; i++) {
      cameras[i].R = rmats[i];
    }
    expect(await stitcher.setTransformAsync(images.cvd, cameras), cv.StitcherStatus.OK);

    final (status, pano) = await stitcher.composePanoramaAsync();
    expect(status, cv.StitcherStatus.OK);
    expect(pano.isEmpty, false);
  });
}
