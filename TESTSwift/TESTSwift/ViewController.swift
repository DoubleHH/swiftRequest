//
//  ViewController.swift
//  TESTSwift
//
//  Created by DoubleHH on 2018/1/14.
//  Copyright © 2018年 com.baidu.iwaimai. All rights reserved.
//

import UIKit

func printSuffixEnum(prefixArray: Array<String>,
                     prefixRange: Range<Int>,
                     middleArray: Array<String>,
                     middleRange: Range<Int>) {
    if prefixRange.lowerBound > prefixRange.upperBound {
        return
    }
    let rootValue = prefixArray[prefixRange.lowerBound]
    let middleIndex = middleArray.index(of: rootValue)!
    var rightIndex = -1
    for index in stride(from: prefixRange.lowerBound, to: prefixRange.upperBound + 1, by: 1) {
        let tempIndex = middleArray.index(of: prefixArray[index])!
        if tempIndex > middleIndex {
            rightIndex = index
            break
        }
    }
    var mRange = Range<Int>.init(uncheckedBounds: (middleRange.lowerBound, middleIndex - 1))
    var pRange = Range<Int>.init(uncheckedBounds: (prefixRange.lowerBound + 1, rightIndex >= 0 ? rightIndex - 1 : prefixRange.upperBound))
    printSuffixEnum(prefixArray: prefixArray,
                    prefixRange: pRange,
                    middleArray: middleArray,
                    middleRange: mRange)
    if rightIndex >= 0 {
        mRange = Range<Int>.init(uncheckedBounds: (middleIndex + 1, middleRange.upperBound))
        pRange = Range<Int>.init(uncheckedBounds: (rightIndex, prefixRange.upperBound))
        printSuffixEnum(prefixArray: prefixArray,
                        prefixRange: pRange,
                        middleArray: middleArray,
                        middleRange: mRange)
    }
    print(rootValue)
}


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.test()
    }

    func test() {
//        let prefixArray = ["A", "B", "C", "G", "D", "E", "F"]
//        let middleArray = ["C", "B", "G", "A", "E", "D", "F"]
        
        let prefixArray = ["A", "D", "E", "F"]
        let middleArray = ["A", "E", "D", "F"]
//
//        let prefixArray = ["A", "B", "C", "G"]
//        let middleArray = ["C", "B", "G", "A"]
        printSuffixEnum(prefixArray: prefixArray,
                        prefixRange: Range<Int>.init(uncheckedBounds: (0, prefixArray.count - 1)),
                        middleArray: middleArray,
                        middleRange: Range<Int>.init(uncheckedBounds: (0, middleArray.count - 1)))
    }
}

