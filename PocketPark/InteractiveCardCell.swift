//
//  InteractiveCardCell.swift
//  PocketPark
//
//  Created by Tom Arthur on 3/22/15.
//
//

import UIKit
import QuartzCore
import MapKit

class InteractiveCardCell: UITableViewCell {

    @IBOutlet weak var interactiveCardView: UIView!
    @IBOutlet weak var interactiveSubCardView: UIView!
    @IBOutlet weak var interactiveLocation: MKMapView!
    @IBOutlet weak var interactiveName: UILabel!
    @IBOutlet weak var interactiveDetails: UILabel!
    @IBOutlet weak var interactiveLastSeen: UILabel!

    
    func loadItem(#title: String, desc: String, lastSeen: String, coordinates: CLLocationCoordinate2D){
        
        interactiveCardView.backgroundColor = UIColor.clearColor()
        
        interactiveSubCardView.layer.cornerRadius = 10
        interactiveSubCardView.layer.masksToBounds = true


        interactiveName.text = title
        interactiveName.font = UIFont(name:"OtterFont", size: 45)
        interactiveName.minimumScaleFactor = 0.5
        interactiveName.adjustsFontSizeToFitWidth = true

        interactiveName.textAlignment = .Center
        interactiveName.sizeToFit()
        interactiveName.layer.cornerRadius = 10
        interactiveName.layer.masksToBounds = true
        
        interactiveDetails.text = desc
        interactiveDetails.textAlignment = .Center
        interactiveDetails.adjustsFontSizeToFitWidth = true
        
        interactiveLastSeen.text = "Last discovered at \(lastSeen)"
        interactiveLastSeen.textColor = UIColor.whiteColor()
        interactiveLastSeen.textAlignment = .Center
        interactiveLastSeen.font = UIFont(name: "HelveticaNeue-UltraLight", size: 12)
        
        
        let spanX = 0.001
        let spanY = 0.001
        var interactiveRegion = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpanMake(spanX, spanY))
        interactiveLocation.setRegion(interactiveRegion, animated: false)
        interactiveLocation.scrollEnabled = false
        interactiveLocation.showsUserLocation = true
        interactiveLocation.layer.cornerRadius = 10
        interactiveLocation.layer.masksToBounds = true
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        annotation.title = title
        interactiveLocation.addAnnotation(annotation)
        
        self.contentView.setTranslatesAutoresizingMaskIntoConstraints(true)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}