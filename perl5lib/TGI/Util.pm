=head1 TGI::Util

 Collection of utility subroutines. This is for the moment considered a stub of such functions and therefore can change dramatically in the future releases ( or dramatically dissapear for what it matters )

=head1 VERSION

Version 0.01
 
=head1 SYNOPSIS

	use TGI::Util qw( fasta );
	my $fh = IO::File->new('input.fasta','r');
	my $record = nextFastaRec($fh);
  
=head1 EXPORT

Nothing exported by default.

tag I<fasta> will export FASTA related functions.That is nextFastaRec() .
tag I<acefile> will export ACE related functions. That is nextContig() and nextAFList().

=head1 FUNCTIONS

=cut 

package TGI::Util;

use strict;
use base qw( Exporter );
use TGI::Exception;
use File::Spec;
use File::HomeDir;
use TGI::Config;

our $VERSION = '0.01';
our @EXPORT_OK = qw( nextFastaRec nextContig nextAFList loadConfig);
our %EXPORT_TAGS =( fasta   => [qw(nextFastaRec)]
                                ,acefile => [qw(nextContig nextAFList)]);


=head2 nextFastaRec($fh)
Reads next fasta record from an already opened fasta file. First fasta record will always be empty due to the fact that end-of-record is considered to be >. So always read and discard first record.	$fh should be an already opened filehandle of a fasta file.
Throws exception in case of problems.

=cut
sub nextFastaRec {
    my $self = shift;
    my $fh = shift;
    my($line,@A,$id);
    return if($fh->eof());
    local $/='>';
    $line = <$fh> || TGI::Exception::IO->throw("Can not read from fasta file.");
    chomp($line);
    @A = split(/\n/,$line);
    $id = shift(@A);
    return {'id' => $id, 'raRows' => \@A};
}
=head2 nextContig($fh)
Reads next contig sequence from an ACE file. Will return a hash reference. I<id> key will be the contig name. I<raRows> will point to an array with the contig sequence splitted by its rows.

=cut
sub nextContig {
    my $self = shift;
    my $fh = shift;
    my($line,@A,$id);
    return if($fh->eof());
    do{
        $line = <$fh> || TGI::Exception::IO->throw("Can not read from ACE file.");
        return if($fh->eof());
    }  until($line =~ m/^CO/); 
    $id =  (split(/\s+/,$line))[1];  
    local $/ = "\n\n";
    $line = <$fh> || TGI::Exception::IO->throw("Can not read from ACE file.");
    $line =~ tr/*\n//d;
    return {'id' => $id, 'raRows' => [unpack("(A60)*",$line)]};
}
=head2 nextAFList($fh)
Reads the next AF list from the $fh ACE file. Will return a reference to an array with all the sequence ids.

=cut
sub nextAFList {
    my $self = shift;
    my $fh = shift;
    my(@Seq_Names);
    return if($fh->eof());
    do{
        $_=<$fh> || TGI::Exception::IO->throw("Can not read from ACE file.");
        return if($fh->eof());
    }  until(m/^AF/);
    push( @Seq_Names, (split(/\s+/))[1]);
        local $/ = "\n\n";
    $_=<$fh> || TGI::Exception::IO->throw("Can not read from ACE file.");
    push( @Seq_Names, m/AF\s+(\w+)/g);
    return \@Seq_Names;
}
=head2 loadConfig($cfgName)
Searches and loads tgicl config file with name $cfgName.
throws an exception in case something goes wrong.

=cut
sub loadConfig {
    my $cfgName = shift;
    my ($cfg);
    my @config_Path = (
        File::Spec->catfile(
            File::Spec->curdir(),
            $cfgName
        ),
        File::Spec->catfile(
            File::HomeDir->my_home(),
            $cfgName
        ),
        File::Spec->catfile(
            (File::Spec->rootdir(), ($^O eq 'MSWin32')?
                                        do{
                                            require Win32;
                                            Win32::GetFolderPath(Win32::CSIDL_LOCAL_APPDATA(), 'CREATE');
                                        }
                                        : "etc" ),
            $cfgName
        )
    );
    
    foreach my $fCfg (@config_Path) {
        if( -e $fCfg ){
            $cfg = TGI::Config->new($fCfg);
            return $cfg;
        }
    }
    TGI::Exception->throw( "Failed to find $cfgName config file in @config_Path" ) if( not $cfg );
}
=head1 COPYRIGHT & LICENSE

Copyright 2010 Valentin Antonescu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
