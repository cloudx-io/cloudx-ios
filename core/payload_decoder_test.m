#import <Foundation/Foundation.h>

// Simple test to decode the payload from logs
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Encoded string from logs: ABsoSAAbKEIVED1DABtQP394IyxfQygwd2RLQwAbKEhLSHwdXhsoSEFnfkZ5b38%2FFkhJNRZKfSRQd1kmYxsoQwBych1fT34nXlNnSAAbKEg%3D
        NSString *encodedString = @"ABsoSAAbKEIVED1DABtQP394IyxfQygwd2RLQwAbKEhLSHwdXhsoSEFnfkZ5b38%2FFkhJNRZKfSRQd1kmYxsoQwBych1fT34nXlNnSAAbKEg%3D";
        
        // URL decode
        NSString *urlDecoded = [encodedString stringByRemovingPercentEncoding];
        NSLog(@"URL Decoded: %@", urlDecoded);
        
        // Base64 decode
        NSData *data = [[NSData alloc] initWithBase64EncodedString:urlDecoded options:0];
        if (data) {
            NSString *base64Decoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Base64 Decoded: %@", base64Decoded);
            
            // Split by semicolons to see individual field values
            NSArray *fields = [base64Decoded componentsSeparatedByString:@";"];
            NSLog(@"Field count: %lu", (unsigned long)fields.count);
            for (int i = 0; i < fields.count; i++) {
                NSLog(@"Field %d: '%@'", i, fields[i]);
            }
        } else {
            NSLog(@"Failed to decode base64");
        }
    }
    return 0;
}
