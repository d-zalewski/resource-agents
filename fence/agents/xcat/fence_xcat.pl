#!/usr/bin/perl

###############################################################################
###############################################################################
##
##  Copyright (C) Sistina Software, Inc.  1997-2003  All rights reserved.
##  Copyright (C) 2004-2007 Red Hat, Inc.  All rights reserved.
##
###############################################################################
###############################################################################

use Getopt::Std;

# Get the program name from $0 and strip directory names
$_=$0;
s/.*\///;
my $pname = $_;

$opt_o = 'reset';        # Default fence action
$opt_r = 'rpower';        # Default fence action

# WARNING!! Do not add code bewteen "#BEGIN_VERSION_GENERATION" and 
# "#END_VERSION_GENERATION"  It is generated by the Makefile

#BEGIN_VERSION_GENERATION
$FENCE_RELEASE_NAME="";
$REDHAT_COPYRIGHT="";
$BUILD_DATE="";
#END_VERSION_GENERATION


sub usage
{
    print "Usage:\n";
    print "\n";
    print "$pname [options]\n";
    print "\n";
    print "Options:\n";
    print "  -h               usage\n";
    print "  -n <name>        nodename\n";
    print "  -o <string>      Action:  on | off | reset (default) | stat\n";
    print "  -r <rpower>      rpower command\n";
    print "  -q               quiet mode\n";
    print "  -V               version\n";

    exit 0;
}

sub fail
{
  ($msg) = @_;
  print $msg."\n" unless defined $opt_q;
  $t->close if defined $t;
  exit 1;
}

sub fail_usage
{
  ($msg)=@_;
  print STDERR $msg."\n" if $msg;
  print STDERR "Please use '-h' for usage.\n";
  exit 1;
}

sub version
{
  print "$pname $FENCE_RELEASE_NAME $BUILD_DATE\n";
  print "$REDHAT_COPYRIGHT\n" if ( $REDHAT_COPYRIGHT );

  exit 0;
}

sub get_options_stdin
{
    my $opt;
    my $line = 0;
    while( defined($in = <>) )
    {
        $_ = $in;
        chomp;

	# strip leading and trailing whitespace
        s/^\s*//;
        s/\s*$//;

	# skip comments
        next if /^#/;

        $line+=1;
        $opt=$_;
        next unless $opt;

        ($name,$val)=split /\s*=\s*/, $opt;

        if ( $name eq "" )
        {  
           print STDERR "parse error: illegal name in option $line\n";
           exit 2;
	}
	
        # DO NOTHING -- this field is used by fenced
	elsif ($name eq "agent" ) { } 

        elsif ($name eq "action" )
        {
            $opt_o = $val;
        }
	elsif ($name eq "nodename" ) 
	{
            $opt_n = $val;
        } 
	elsif ($name eq "rpower" ) 
	{
            $opt_r = $val;
        } 

    }
}

######################################################################33
# MAIN

if (@ARGV > 0) {
   getopts("hn:o:r:qV") || fail_usage ;

   usage if defined $opt_h;
   version if defined $opt_V;

   fail_usage "Unknown parameter." if (@ARGV > 0);

   fail_usage "No '-n' flag specified." unless defined $opt_n;
   fail_usage "Unrecognised action '$opt_o' for '-o' flag"
      unless $opt_o =~ /^(on|off|reset|stat)$/;

} else {
   get_options_stdin();

   fail "failed: no plug number" unless defined $opt_n;
   fail "failed: unrecognised action: $opt_o"
      unless $opt_o =~ /^(on|off|reset|stat)$/;
}

pipe (RDR,WTR);

if ( $pid=fork() == 0 )
{
   close RDR;

   open STDOUT, ">&WTR";
   exec "$opt_r $opt_n $opt_o" or die "failed to exec \"$opt_r\"\n";
}

close WTR;

wait;

if ( $? != 0 )
{
   die "failed: rpower error: exit $?\n"
}

$found=0;
$status="";
while (<RDR>)
{
   chomp;

   if ( $_ =~ /^(\S+): (\S+)$/)
   {
      if ($opt_n eq $1) 
      {
         $status = $2;

         if (($opt_o eq $2) || ($opt_o eq "stat"))
         {
            $found=1;
            last;
         }
      }
   }
}

print (($found ? "success":"failed") . ": $opt_n $status\n")
   unless defined $opt_q;

exit ($found ? 0 : 1 );









