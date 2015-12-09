//
//  ObsDetailMapCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/8/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import MapKit;

#import <UIKit/UIKit.h>

@interface ObsDetailMapCell : UITableViewCell

@property IBOutlet UILabel *locationNameLabel;
@property IBOutlet MKMapView *mapView;

@end
