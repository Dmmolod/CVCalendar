//
//  CVCalendarDayView.swift
//  CVCalendar
//
//  Created by E. Mozharovsky on 12/26/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

class CVCalendarDayView: UIView {
    
    // MARK: - Public properties

    var weekView: CVCalendarWeekView?
    let weekdayIndex: Int?
    let date: CVDate?
    
    var dayLabel: UILabel?
    var circleView: CVCircleView?
    var topMarker: CALayer?
    var dotMarker: CVCircleView?
    
    var isOut = false
    var isCurrentDay = false
    
    // MARK: - Initialization
    
    init(weekView: CVCalendarWeekView, frame: CGRect, weekdayIndex: Int) {
        super.init()
        
        self.weekView = weekView
        self.frame = frame
        self.weekdayIndex = weekdayIndex
        
        func hasDayAtWeekdayIndex(weekdayIndex: Int, weekdaysDictionary: [Int : [Int]]) -> Bool {
            let keys = weekdaysDictionary.keys
            
            for key in keys.array {
                //println("Key: \(key), weekday index:\(weekdayIndex)")
                if key == weekdayIndex {
                    return true
                }
            }
            
            return false
        }
        
        
        var day: Int?
        
        let weekdaysIn = self.weekView!.weekdaysIn!
        if let weekdaysOut = self.weekView?.weekdaysOut {
            if hasDayAtWeekdayIndex(self.weekdayIndex!, weekdaysOut) {
                self.isOut = true
                day = weekdaysOut[self.weekdayIndex!]![0]
            } else if hasDayAtWeekdayIndex(self.weekdayIndex!, weekdaysIn) {
                day = weekdaysIn[self.weekdayIndex!]![0]
            }
        } else {
            day = weekdaysIn[self.weekdayIndex!]![0]
        }
        

        
        if day == self.weekView!.monthView!.currentDay && !self.isOut {
            let manager = CVCalendarManager.sharedManager
            let dateRange = manager.dateRange(self.weekView!.monthView!.date!)
            let currentDateRange = manager.dateRange(NSDate())
            
            if dateRange.month == currentDateRange.month && dateRange.year == currentDateRange.year {
                self.isCurrentDay = true
            }
            
        }
        

        
        var shouldShowDaysOut = self.weekView!.monthView!.calendarView!.shouldShowWeekdaysOut!
        
        let calendarManager = CVCalendarManager.sharedManager
        let year = calendarManager.dateRange(self.weekView!.monthView!.date!).year
        var month: Int? = calendarManager.dateRange(self.weekView!.monthView!.date!).month
        if self.isOut {
            if day > 20 {
                month! -= 1
            } else {
                month! += 1
            }
            
            if !shouldShowDaysOut {
                self.hidden = true
            }
        }
        
        self.date = CVDate(day: day!, month: month!, year: year)
        
        self.labelSetup()
        self.topMarkerSetup()
        self.setupGestures()
        self.setupDotMarker()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Properties setup
    
    func labelSetup() {
        let appearance = CVCalendarViewAppearance.sharedCalendarViewAppearance
        
        self.dayLabel = UILabel()
        self.dayLabel!.text = String(self.date!.day!)
        self.dayLabel!.textAlignment = NSTextAlignment.Center
        self.dayLabel!.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        
        var font: UIFont? = UIFont.systemFontOfSize(appearance.dayLabelWeekdayTextSize!)
        var color: UIColor?
        if self.isOut {
            color = appearance.dayLabelWeekdayOutTextColor
        } else if self.isCurrentDay {
            let coordinator = CVCalendarDayViewControlCoordinator.sharedControlCoordinator
            if coordinator.selectedDayView == nil {
                self.weekView!.monthView!.receiveDayViewTouch(self)
            } else {
                color = appearance.dayLabelPresentWeekdayTextColor
                font = UIFont.boldSystemFontOfSize(appearance.dayLabelPresentWeekdayTextSize!)
            }
            
        } else {
            color = appearance.dayLabelWeekdayInTextColor
        }
        
        
        if color != nil && font != nil {
            self.dayLabel!.textColor = color!
            self.dayLabel!.font = font
        }
        
        self.addSubview(self.dayLabel!)
    }
    
    
    func topMarkerSetup() {
        let height = CGFloat(0.5)
        let layer = CALayer()
        layer.borderColor = UIColor.grayColor().CGColor
        layer.borderWidth = height
        layer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), height)
        
        self.topMarker = layer
        
        self.layer.addSublayer(self.topMarker!)
    }
    
    func setupDotMarker() {
        if let delegate = self.weekView!.monthView!.calendarView!.delegate {
            if delegate.dotMarker(shouldShowOnDayView: self) {
                var color = delegate.dotMarker(colorOnDayView: self)
                let width: CGFloat = 13
                let height = width
                
                let x = self.frame.width / 2
                let y = CGRectGetMaxY(self.frame) - self.frame.height / 5
                
                let frame = CGRectMake(0, 0, width, height)
                
                if self.isOut {
                    color = UIColor.grayColor()
                }
                
                self.dotMarker = CVCircleView(frame: frame, color: color, _alpha: 1)
                self.dotMarker?.center = CGPointMake(x, y)
                
                self.insertSubview(self.dotMarker!, atIndex: 0)
                

            }
        }
    }
    
    // MARK: - Events handling
    
    func setupGestures() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "dayViewTapped")
        self.addGestureRecognizer(tapRecognizer)
    }
    
    func dayViewTapped() {
        let monthView = self.weekView!.monthView!
        monthView.receiveDayViewTouch(self)
    }
    
    // MARK: - Label states management
    
    private var diff: CGFloat?
    private var dotMarkerMoved = false
    func setDayLabelHighlighted() {
        let appearance = CVCalendarViewAppearance.sharedCalendarViewAppearance
        
        var color: UIColor?
        var _alpha: CGFloat?
        
        if self.isCurrentDay {
            color = appearance.dayLabelPresentWeekdayHighlightedBackgroundColor!
            _alpha = appearance.dayLabelPresentWeekdayHighlightedBackgroundAlpha!
            self.dayLabel?.textColor = appearance.dayLabelPresentWeekdayHighlightedTextColor!
            self.dayLabel?.font = UIFont.boldSystemFontOfSize(appearance.dayLabelPresentWeekdayHighlightedTextSize!)
        } else {
            color = appearance.dayLabelWeekdayHighlightedBackgroundColor
            _alpha = appearance.dayLabelWeekdayHighlightedBackgroundAlpha
            self.dayLabel?.textColor = appearance.dayLabelWeekdayHighlightedTextColor
            self.dayLabel?.font = UIFont.boldSystemFontOfSize(appearance.dayLabelWeekdayHighlightedTextSize!)
        }
        
        self.circleView = CVCircleView(frame: CGRectMake(0, 0, self.frame.width, self.frame.height), color: color!, _alpha: _alpha!)
        self.insertSubview(self.circleView!, atIndex: 0)
        
        if self.dotMarker != nil {
            let radius = (self.circleView!.frame.size.width - 10)/2
            let center = CGPointMake((self.circleView!.frame.size.width)/2, self.circleView!.frame.size.height/2)
            let maxArcPointY = center.y + radius
            self.diff = maxArcPointY - self.dotMarker!.frame.origin.y
        
            if diff > 0 {
                self.diff = abs(self.diff!)
                self.dotMarkerMoved = true
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.dotMarker!.frame.origin.y += self.diff!
                }, completion: nil)
            }
        }

    }
    
    func setDayLabelUnhighlighted() {
        let appearance = CVCalendarViewAppearance.sharedCalendarViewAppearance
        
        var color: UIColor?
        if self.isOut {
            color = appearance.dayLabelWeekdayOutTextColor
        } else if self.isCurrentDay {
            color = appearance.dayLabelPresentWeekdayTextColor
        } else {
            color = appearance.dayLabelWeekdayInTextColor
        }
        
        var font: UIFont?
        if self.isCurrentDay {
            if appearance.dayLabelPresentWeekdayInitallyBold {
                font = UIFont.boldSystemFontOfSize(appearance.dayLabelPresentWeekdayTextSize!)
            } else {
                font = UIFont.systemFontOfSize(appearance.dayLabelPresentWeekdayTextSize!)
            }
        } else {
            font = UIFont.systemFontOfSize(appearance.dayLabelWeekdayTextSize!)
        }
        
        self.dayLabel?.textColor = color
        self.dayLabel?.font = font
        
        if self.dotMarker != nil {
            if self.dotMarkerMoved {
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.dotMarker!.frame.origin.y -= self.diff!
                }, completion: {_ in
                    self.dotMarkerMoved = false
                })
            }
        }
        
        self.circleView?.removeFromSuperview()
        self.circleView = nil
    }
    
    // MARK: - Content reload
    
    func reloadContent() {
        self.setupDotMarker()
        var shouldShowDaysOut = self.weekView!.monthView!.calendarView!.shouldShowWeekdaysOut!
        if !shouldShowDaysOut {
            if self.isOut {
                self.hidden = true
            }
        } else {
            if self.isOut {
                self.hidden = false
            }
        }
        
        self.dayLabel?.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        
        self.topMarker?.frame.size.width = self.frame.width
        
        if self.circleView != nil {
            self.setDayLabelUnhighlighted()
            self.setDayLabelHighlighted()
        }
        
    }
    
}