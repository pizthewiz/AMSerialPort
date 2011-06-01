//
//  AppController.m
//  AMSerialTest
//
//		2009-09-09		Andreas Mayer
//		- fixed memory leak in -serialPortReadData:


#import "AppController.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

@interface AppController()
- (void)_setupPort;
@end

@implementation AppController

@synthesize port;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [port release];

    [super dealloc];
}

#pragma mark -

- (void)awakeFromNib
{
	[deviceTextField setStringValue:@"/dev/cu.modem"]; // internal modem
	[inputTextField setStringValue: @"ati"]; // will ask for modem type

	// register for port add/remove notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
	[AMSerialPortList sharedPortList]; // initialize port list to arm notifications
}

#pragma mark - SERIAL PORT READ DELEGATE

- (void)serialPort:(AMSerialPort *)sendPort didReadData:(NSData *)data
{
	// this method is called if data arrives 
	if ([data length] > 0) {
		NSString *text = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		[outputTextView insertText:text];
		[text release];
		// continue listening
		[sendPort readDataInBackground];
	} else { // port closed
		[outputTextView insertText:@"port closed\r"];
	}
	[outputTextView setNeedsDisplay:YES];
	[outputTextView displayIfNeeded];
}

#pragma mark - SERIAL PORT NOTIFICATIONS

- (void)didAddPorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didAddPorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}

- (void)didRemovePorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didRemovePorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}

#pragma mark - ACTIONS

- (IBAction)listDevices:(id)sender
{
    for (AMSerialPort* aPort in [[AMSerialPortList sharedPortList] serialPorts]) {
		// print port name
		[outputTextView insertText:[aPort name]];
		[outputTextView insertText:@":"];
		[outputTextView insertText:[aPort bsdPath]];
		[outputTextView insertText:@"\r"];
	}
	[outputTextView setNeedsDisplay:YES];
}

- (IBAction)chooseDevice:(id)sender
{
	// new device selected
	[self _setupPort];
}

- (IBAction)send:(id)sender
{
	NSString *sendString = [[inputTextField stringValue] stringByAppendingString:@"\r"];

	if(!self.port) {
		// open a new port if we don't already have one
		[self _setupPort];
	}

	if([self.port isOpen]) { // in case an error occured while opening the port
		[self.port writeString:sendString usingEncoding:NSUTF8StringEncoding error:NULL];
	}
}

#pragma mark - PRIVATE

- (void)_setupPort
{
    NSString *deviceName = [deviceTextField stringValue];
	if (![deviceName isEqualToString:self.port.bsdPath]) {
		[self.port close];
        self.port = [[AMSerialPortList sharedPortList] serialPortWithPath:deviceName];
		
		// register as self as delegate for port
		self.port.readDelegate = self;
		
		[outputTextView insertText:@"attempting to open port\r"];
		[outputTextView setNeedsDisplay:YES];
		[outputTextView displayIfNeeded];
		
		// open port - may take a few seconds ...
		if ([self.port open]) {
			
			[outputTextView insertText:@"port opened\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];
            
			// listen for data in a separate thread
			[self.port readDataInBackground];
			
		} else { // an error occured while creating port
			[outputTextView insertText:@"couldn't open port for device "];
			[outputTextView insertText:deviceName];
			[outputTextView insertText:@"\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];
            self.port = nil;
		}
	}
}

@end
