/**
 *
 * 	DarkLightning
 *
 *
 *
 *	The MIT License (MIT)
 *
 *	Copyright (c) 2017 Jens Meder
 *
 *	Permission is hereby granted, free of charge, to any person obtaining a copy of
 *	this software and associated documentation files (the "Software"), to deal in
 *	the Software without restriction, including without limitation the rights to
 *	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 *	the Software, and to permit persons to whom the Software is furnished to do so,
 *	subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in all
 *	copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public final class SocketWriteStream: WriteStream {
	private let outputStream: Memory<OutputStream?>
	
	// MARK: Init
    
	public required init(outputStream: Memory<OutputStream?>) {
        self.outputStream = outputStream
    }
    
    // MARK: WriteStream
	
	public func write(data: Data) {
		if !data.isEmpty, let outputStream = outputStream.rawValue {
			var bytesWritten = 0
			do {
				repeat {
					let subData = data.dropFirst(bytesWritten)
					try bytesWritten += outputStream.write(data: subData)
				} while(bytesWritten != data.count)
			} catch let error {
				NSLog("Error occured while writing data to stream: \(error) [This is ignored]")
			}
		}
	}
}

// Taken from https://developer.apple.com/forums/thread/116309
// to safely write to a stream from Data
extension OutputStream {

	func write(buffer: UnsafeRawBufferPointer) throws -> Int {
		// This check ensures that `baseAddress` will never be `nil`.
		guard !buffer.isEmpty else { return 0 }
		let bytesWritten = self.write(buffer.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: buffer.count)
		if bytesWritten < 0 {
			throw self.guaranteedStreamError
		}
		return bytesWritten
	}

	func write(data: Data) throws -> Int {
		return try data.withUnsafeBytes { buffer -> Int in
			try self.write(buffer: buffer)
		}
	}
}

extension Stream {
	var guaranteedStreamError: Error {
		if let error = self.streamError {
			return error
		}
		// If this fires, the stream read or write indicated an error but the
		// stream didn’t record that error.  This is definitely a bug in the
		// stream implementation, and we want to know about it in our Debug
		// build. However, there’s no reason to crash the entire process in a
		// Release build, so in that case we just return a dummy error.
		assert(false)
		return NSError(domain: NSPOSIXErrorDomain, code: Int(ENOTTY), userInfo: nil)
	}
}
