#!perl -w
package main; # Make Devel::PerlySense happy

## Test environment
use Test::More 0.98  tests => 10;
use Test::MockObject;

# Modules we need
use File::Temp;
use HTTP::Request::Common;
use Plack::Util;
use Encode qw(decode);

use Act::Config;
use Act::Middleware::ErrorPage;

## Test preparations ---------------------------------------------------
## Some test data
my $original_body = 'Original response';
my $camel = "\x{1f42a}"; # The unicode camel, famous since GPW2019
my $path_info = '-';
# Accept header for Firefox > 66
my $ff_a = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";

## Mock PSGI environment
# The PSGI app will be changed during the tests
my $app;

# Make a mock PSGI server to be passed to the call() method
# which references the $app from above
my $psgi_server = Test::MockObject->new;
$psgi_server->set_bound('app',\$app);

# Make a new app for each group of tests
sub app_call {
    my ($code,$accept) = @_;

    $accept //= '*/*';
    $app = sub { return [$code,[],[$original_body]]; };
    my $response = Act::Middleware::ErrorPage::call(
        $psgi_server,
        {
            HTTP_ACCEPT => $accept,
            PATH_INFO   => $path_info,
        }
    );
    return $response;
}

# Create a temporary templates directory
my $mock_acthome = File::Temp->newdir(CLEANUP => 0)
    or die "No temporary directory available: '$!'";
my $mock_includes = "$mock_acthome/templates";
mkdir $mock_includes
    or die "No mock template directory available: '$!'";

# C create files 'common' (required by Act::Template)
#    and 'error404' (used by the Module Under Test)
open (my $common,'>:encoding(UTF-8)',"$mock_includes/common")
    or die "No mock template for pre_process available: '$!'";
print $common "common[% CLEAR %]";
close $common;
open (my $template,'>:encoding(UTF-8)',"$mock_includes/error404")
    or die "No mock template available: '$!'";
print $template "${camel}[% path_info %]$camel";
close $template;

# Activate the fake template and suppress a warning
$Config->home($mock_acthome);
$Request{language} = 'en';


## Tests start here ----------------------------------------------------
{
    # A successful request
    my $response = app_call(200);
    is ($response->[0],200,
        "Successful request processed");
    is ($response->[2][0],$original_body,
        "Successful requests must not change the body");
}

{
    # A 404 request for an image
    my $response = app_call(404,'image/*');
    is ($response->[0],404,
        "Image not found");
    is ($response->[2][0],$original_body,
        "No HTML response injected into image body");
}

{
    # A 404 request for a HTML page with Firefox Accept header
    my $response = app_call(404,$ff_a);
    is ($response->[0],404,
        "Non-existing HTML page still not found");
    my $headers = $response->[1];
    is (Plack::Util::header_get($headers,'Content-Length'),9,
        "Content length in bytes is correct");
    is (Plack::Util::header_get($headers,'Content-Type'),
        'text/html; charset=UTF-8',
        "Content type set to 'text/html'");
    my $body = $response->[2][0];
    my $decoded = decode('UTF-8',$body,Encode::FB_CROAK);
    is ($decoded,$camel . $path_info . $camel,
        "Template processed correctly for 'text/html'");
}

{
    # A 404 request for a page accepting 'text/*'
    my $response = app_call(404,'text/*');
    # same as previous, so just perform one test
    my $body = $response->[2][0];
    my $decoded = decode('UTF-8',$body,Encode::FB_CROAK);
    is ($decoded,$camel . $path_info . $camel,
        "Template processed correctly for 'text/*'");
}

{
    # Overriding the template with a custom template (created here)
    # No error handling here - a failing test case is good enough
    my $mock_static = "$mock_acthome/static";
    mkdir $mock_static;
    open (my $template,'>:encoding(UTF-8)',"$mock_static/error404")
        or die "No mock template available: '$!'";
    print $template 'TIMTOWTDI';
    close $template;
    sleep 2; # ugly, ugly... but otherwise TT's cache gets in the way

    # A 404 request for a HTML page with Firefox Accept header
    my $response = app_call(404,$ff_a);
    my $body = $response->[2][0];
    is ($body,'TIMTOWTDI',
        "Custom template processed correctly");

    unlink "$mock_static/error404";
}
