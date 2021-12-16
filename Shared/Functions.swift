//
//  Functions.swift
//  Byte
//
//  Created by Kristian Pennacchia on 13/8/21.
//  Copyright © 2021 Kristian Pennacchia. All rights reserved.
//

import Foundation

class TaskCancellationSource {
    var isCancelled = false
}

func performAfter(duration: DispatchTimeInterval, completion: @escaping () -> Void) -> TaskCancellationSource {
    let source = TaskCancellationSource()

    DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [source] in
        guard source.isCancelled == false else { return }

        completion()
    }

    return source
}
