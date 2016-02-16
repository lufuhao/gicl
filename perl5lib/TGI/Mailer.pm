=head1 TGI::Mailer

The old tgi Mailer with a face lift job. It is used to send email notifications in case the user want that.

This module depends on I<sendmail> and should become obsolete (hopefully) in future releases.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 Old way of sending email notifications.

=head1 FUNCTIONS

=cut

package TGI::Mailer;
use strict;
use POSIX 'uname';
use IO::File;
use TGI::Exception;
our $VERSION = '0.02';
our (@EXPORT_OK);

@EXPORT_OK = qw( send_mail );

my ($def_host,$def_domain);

INIT {

   my $thisHost= (&POSIX::uname)[1]; # can't trust HOST envvar under condor, because for getenv=TRUE
                          # it will either inherit HOST and HOSTNAME from submitter env
                          # or not set anything for getenv=FALSE
                          # --> so we use POSIX uname() call here
   chomp($thisHost);
   $thisHost=lc($thisHost);
   my ($thisDomain)=($thisHost=~/^[\w\-]+\.(.+)/);
# if the above fails, and if the user has the courage to look into this script
# then he/she can set default domain here manually:
# e.g. 
# my $def_domain='google.com';
# However, in the general case we should rise an exception but we won't do this right now.
   $def_domain = $thisDomain;
   $def_host = $thisHost;
   if(not $thisDomain){
      $def_domain = "localdomain";
   }
}
=head2 send_mail

 The only function exported. It will send an email. 

=cut
sub send_mail {
 my $hash=shift;
 my ($fhTemp, $file);
;
 $hash->{'from'}=$ENV{'USER'}.'@'.$def_host
    unless defined($hash->{'from'});
 my $to=$hash->{'to'};
 unless ($to) {
    $hash->{'to'}=$ENV{'USER'}.'@'.$def_domain;
    }
   else {
    $hash->{'to'}=$to.'@'.$def_domain unless $to =~ m/@/;
    }
    
 if (defined($hash->{'file'})) {
   #warning: assumes it's a decent, short text file!
   local $/=undef; #read whole file
   $fhTemp = IO::File->new('<'.$hash->{'file'}) || TGI::Exception::IO->throw("Cannot open file ".$hash->{'file'});
   $file=<$fhTemp>;
   $fhTemp->close();
   }
 my $body = $hash->{'body'};
 $body.=$file;
 my $fh;
 $fh = IO::File->new('| /usr/lib/sendmail -t -oi') || TGI::Exception::IO->throw("Mailer.pm error: Cannot open the sendmail pipe\n");
 $fh->print("To: $hash->{to}\n");
 $fh->print("From: $hash->{from}\n");
 $fh->print("Subject: $hash->{subj}\n\n");
 $fh->print($body);
 $fh->close();
}
=head1 ACKNOWLEDGEMENTS

Hail to Geo Pertea, the founding father of first TGICL release.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Valentin Antonescu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;

