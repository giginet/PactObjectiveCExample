
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#include "HelloClient.h"
@import PactConsumerSwift;
@import UIKit;

@interface PactTest : XCTestCase
@property (strong, nonatomic) MockService *mockService;
@property (strong, nonatomic) HelloClient *helloClient;
@end

@implementation PactTest

- (void)setUp {
  [super setUp];
  XCTestExpectation *exp = [self expectationWithDescription:@"Pacts all verified"];
  self.mockService = [[MockService alloc] initWithProvider:@"Provider" consumer:@"consumer" done:^(PactVerificationResult result) {
    XCTAssert(result == PactVerificationResultPassed);
    [exp fulfill];
  }];
  self.helloClient = [[HelloClient alloc] initWithBaseUrl:self.mockService.baseUrl];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testPact {
  typedef void (^CompleteBlock)();
  [[[self.mockService uponReceiving:@"a request for hello"]
                      withRequestHTTPMethod:PactHTTPMethodGET path:@"/sayHello" query:nil headers:nil body: nil]
                      willRespondWithHTTPStatus:200 headers:@{@"Content-Type": @"application/json"} body: [Matcher somethingLike:@"Hello"] ];
  
  [self.mockService run:^(CompleteBlock testComplete) {
      NSString *requestReply = [self.helloClient sayHello];
      XCTAssertEqualObjects(requestReply, @"Hello");
      testComplete();
    }
  ];
  
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testWithQueryParams {
  typedef void (^CompleteBlock)();
  
  [[[self.mockService uponReceiving:@"a request friends"]
                      withRequestHTTPMethod:PactHTTPMethodGET path:@"/friends" query: @{ @"age" : @"30", @"child" : @"Mary" } headers:nil body: nil]
   willRespondWithHTTPStatus:200 headers:@{@"Content-Type": @"application/json"} body: @{ @"friends": @[ @{ @"id": [Matcher termWithMatcher:@"[0-9]+" generate:@"1234"] } ] } ];
  
  [self.mockService run:^(CompleteBlock testComplete) {
      NSString *response = [self.helloClient findFriendsByAgeAndChild];
      XCTAssertEqualObjects(response, @"{\"friends\":[{\"id\":\"1234\"}]}");
      testComplete();
    }
  ];
  
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end