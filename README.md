# AFURLConnectionByteSpeedMeasure

`AFURLConnectionByteSpeedMeasure` is a drop in extension for AFNetworking to measure download and upload speed of an `AFURLConnectionOperation` and estimate completion times.

## Usage

``` objc
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://download.thinkbroadband.com/1GB.zip"]];
AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
operation.downloadSpeedMeasure.active = YES;

[operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
	double progress = (double)totalBytesRead / (double)totalBytesExpectedToRead;

	double speedInBytesPerSecond = operation.downloadSpeedMeasure.speed;
	NSString *humanReadableSpeed = operation.downloadSpeedMeasure.humanReadableSpeed;

	NSTimeInterval remainingTimeInSeconds = [operation.downloadSpeedMeasure remainingTimeOfTotalSize:totalBytesExpectedToRead numberOfCompletedBytes:totalBytesRead];
	NSString *humanReadableRemaingTime = [operation.downloadSpeedMeasure humanReadableRemainingTimeOfTotalSize:totalBytesExpectedToRead numberOfCompletedBytes:totalBytesRead];
}];
```

## Lincense 
MIT
