//
//  CGAffineTransformUtils.swift
//  Noteshelf
//
//  Created by Akshay on 16/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import CoreGraphics

extension CGAffineTransform {
    var angle: CGFloat {
        return atan2(self.b, self.a)
    }

    var scaleX: CGFloat {
        return sqrt(self.a * self.a + self.c * self.c)
    }

    var scaleY: CGFloat {
        return sqrt(self.b * self.b + self.d * self.d)
    }

    var translationX: CGFloat {
        return self.tx
    }

    var translationY: CGFloat {
        return self.ty
    }
}
