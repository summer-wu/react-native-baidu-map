//
//  RCTBaiduMapViewManager.m
//  RCTBaiduMap
//
//  Created by lovebing on Aug 6, 2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#import "BaiduMapViewManager.h"
#import "RNBMAuthDelegate.h";
#import "BMKPointAnnotationPro.h";

@implementation BaiduMapViewManager;

static NSString *markerIdentifier = @"markerIdentifier";
static NSString *clusterIdentifier = @"clusterIdentifier";

RCT_EXPORT_MODULE(BaiduMapView)

RCT_EXPORT_VIEW_PROPERTY(mapType, int)
RCT_EXPORT_VIEW_PROPERTY(zoom, float)
RCT_EXPORT_VIEW_PROPERTY(showsUserLocation, BOOL);
RCT_EXPORT_VIEW_PROPERTY(scrollGesturesEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(zoomGesturesEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(trafficEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(baiduHeatMapEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(clusterEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(locationData, NSDictionary*)
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)

RCT_CUSTOM_VIEW_PROPERTY(center, CLLocationCoordinate2D, BaiduMapView) {
    [view setCenterCoordinate:json ? [RCTConvert CLLocationCoordinate2D:json] : defaultView.centerCoordinate];
}

+ (void)initSDK:(NSString*)key {
    BMKMapManager* _mapManager = [[BMKMapManager alloc]init];
    static RNBMAuthDelegate *authDelegate = nil;
    if (!authDelegate) {
        authDelegate = [RNBMAuthDelegate new];
    }
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:key authDelegate:authDelegate];
    BOOL ret = [_mapManager start:key  generalDelegate:nil];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
}

- (UIView *)view {
    BaiduMapView* mapView = [[BaiduMapView alloc] init];
    mapView.delegate = self;
    return mapView;
}

- (void)mapview:(BMKMapView *)mapView onDoubleClick:(CLLocationCoordinate2D)coordinate {
    NSLog(@"onDoubleClick");
    NSDictionary* event = @{
                            @"type": @"onMapDoubleClick",
                            @"params": @{
                                    @"latitude": @(coordinate.latitude),
                                    @"longitude": @(coordinate.longitude)
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapView:(BMKMapView *)mapView onClickedMapBlank:(CLLocationCoordinate2D)coordinate {
    NSLog(@"onClickedMapBlank");
    NSDictionary* event = @{
                            @"type": @"onMapClick",
                            @"params": @{
                                    @"latitude": @(coordinate.latitude),
                                    @"longitude": @(coordinate.longitude)
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView {
    NSDictionary* event = @{
                            @"type": @"onMapLoaded",
                            @"params": @{}
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view {
    NSDictionary* event = @{
                            @"type": @"onMarkerClick",
                            @"params": @{
                                    @"title": [[view annotation] title],
                                    @"position": @{
                                            @"latitude": @([[view annotation] coordinate].latitude),
                                            @"longitude": @([[view annotation] coordinate].longitude)
                                            }
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapView:(BMKMapView *)mapView onClickedMapPoi:(BMKMapPoi *)mapPoi {
    NSLog(@"onClickedMapPoi");
    NSDictionary* event = @{
                            @"type": @"onMapPoiClick",
                            @"params": @{
                                    @"name": mapPoi.text,
                                    @"uid": mapPoi.uid,
                                    @"latitude": @(mapPoi.pt.latitude),
                                    @"longitude": @(mapPoi.pt.longitude)
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation {
    NSLog(@"viewForAnnotation");
    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        ClusterAnnotation *cluster = (ClusterAnnotation*)annotation;
        BMKPinAnnotationView *annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:clusterIdentifier];
        UILabel *annotationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        annotationLabel.textColor = [UIColor whiteColor];
        annotationLabel.font = [UIFont systemFontOfSize:11];
        annotationLabel.textAlignment = NSTextAlignmentCenter;
        annotationLabel.hidden = NO;
        annotationLabel.text = [NSString stringWithFormat:@"%ld", cluster.size];
        annotationLabel.backgroundColor = [UIColor greenColor];
        annotationView.alpha = 0.8;
        [annotationView addSubview:annotationLabel];

        if (cluster.size == 1) {
            annotationLabel.hidden = YES;
            annotationView.pinColor = BMKPinAnnotationColorRed;
        }
        if (cluster.size > 20) {
            annotationLabel.backgroundColor = [UIColor redColor];
        } else if (cluster.size > 10) {
            annotationLabel.backgroundColor = [UIColor purpleColor];
        } else if (cluster.size > 5) {
            annotationLabel.backgroundColor = [UIColor blueColor];
        } else {
            annotationLabel.backgroundColor = [UIColor greenColor];
        }
        [annotationView setBounds:CGRectMake(0, 0, 22, 22)];
        annotationView.draggable = YES;
        annotationView.annotation = annotation;
        return annotationView;
    } else if ([annotation isKindOfClass:[BMKPointAnnotationPro class]]) {
        BMKPointAnnotationPro * annotationPro = annotation;
        return annotationPro.getAnnotationView(annotation);
    } else {
        @throw [NSException exceptionWithName:@"必须用BMKPointAnnotationPro" reason:@"" userInfo:nil];
    }
    return nil;
}

- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay {
    NSLog(@"viewForOverlay");
    BaiduMapView *baidumMapView = (BaiduMapView *) mapView;
    OverlayView *overlayView = [baidumMapView findOverlayView:overlay];
    if (overlayView == nil) {
        return nil;
    }
    if ([overlay isKindOfClass:[BMKArcline class]]) {
        BMKArclineView *arclineView = [[BMKArclineView alloc] initWithArcline:overlay];
        arclineView.strokeColor = [UIColor blueColor];
        arclineView.lineDash = YES;
        arclineView.lineWidth = 6.0;
        return arclineView;
    } else if([overlay isKindOfClass:[BMKCircle class]]) {
        BMKCircleView *circleView = [[BMKCircleView alloc] initWithCircle:overlay];
        return circleView;
    } else if([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView *polylineView = [[BMKPolylineView alloc] initWithPolyline:overlay];
        polylineView.strokeColor = [OverlayUtils getColor:overlayView.strokeColor];
        polylineView.lineWidth = overlayView.lineWidth;
        return polylineView;
    }
    return nil;
}

- (void)mapStatusDidChanged: (BMKMapView *)mapView {
    CLLocationCoordinate2D targetGeoPt = [mapView getMapStatus].targetGeoPt;
    NSDictionary* event = @{
                            @"type": @"onMapStatusChange",
                            @"params": @{
                                    @"target": @{
                                            @"latitude": @(targetGeoPt.latitude),
                                            @"longitude": @(targetGeoPt.longitude)
                                            },
                                    @"zoom": @"",
                                    @"overlook": @""
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)sendEvent:(BaiduMapView *)mapView params:(NSDictionary *)params {
    if (!mapView.onChange) {
        return;
    }
    mapView.onChange(params);
}

@end
