=head1 TGI::DBDrv::Driver

 Base class for specific RDBMS interface for tgicl.
 
=head1 SYNOPSIS

  Do not use this directly, of course. 
  
=head1 VERSION

Version 0.01

=head1 FUNCTIONS

=cut 

package TGI::DBDrv::Driver;

use strict;
use IO::File;
use TGI::Exception;
use TGI::Util qw( :fasta :acefile );

our $VERSION = '0.01';

my $boom = sub{die("You should provide an implementation for this method!");};

# These SQL statements should work in any DBMS.
# For now is ok to keep them private, but if this will grow we will have to change our strategy.
my %gSQL = (
      'insert_est_asm'   =>  q{insert into asm_to_est(asm_id, est_id)
                               select a.id,e.id
                                from assembly a, est e, asm_to_est_temp n
                                where a.id=n.asm_id and e.name=n.est_name}
  ,   'insert_est_names'  =>  q{insert into asm_to_est_temp(asm_id,est_name) values(?, ?)}
  ,   'insert_assembly'   =>  q{insert into assembly(id,seq_id,name)     values (?, ?, ?)}
  ,   'insert_sequence'   =>  q{insert into sequence(id,row_no,seq_row)  values(?, ?, ?)}
  ,   'insert_est'        =>  q{insert into est(id,seq_id,name)          values(?, ?, ?) }
  ,   'id_select'         =>  q{select max(id) from } 
);

# **************    Public Methods Section    **************
=head2 new()
	constructor.
=cut
sub new {
    my ($classtype, $hParams)=@_; 
    my $self={};
    bless($self, $classtype);
    $self->_Init($hParams);
    return($self);
}

# Should connect to the database
sub _Init {$boom->();}
# Reset the DB. (eg. recreate the schema )
sub reset {$boom->();}
# Will reset the asm_to_est table. This usually is dependent of your DBMS.
sub _reset_asm2est_temp {$boom->();}
# Lock a table
sub _lock_table {$boom->();}
# Unlock a table
sub _unlock_table{$boom->();}

=head2 _get_max_id()
General get_last_id() function in case the DBI last_insert_id is not working. Internal use only.
=cut
sub _get_max_id {
    my $self = shift;
    my $tableName = shift;
    my $sql = $gSQL{'id_select'} . " " . $tableName;
    return $self->{'_DBH'}->selectrow_arrayref($sql)->[0];
}

=head2 load_est_fasta(file_Name)

 Will load the input est fasta file into the database. Will throw an exception in case something wrong happends.
This a safe method that should work in any DBMS. Override this with a bulk load for better performance. You should implement the method in yourspecific DBMS driver and in case of an exception you should fall back to this safe method. 
    
=cut

sub load_est_fasta  {
    my $self = shift;
    my $fName = shift;
    my ($fh,$fastaRec,$est_id,$seq_id);
    my ($sthEst, $sthSequence,$raRows,$dbh);
    $fh = IO::File->new($fName,'r');
    TGI::Exception::IO->throw("Can not open $fName.") if(not $fh);
    $dbh = $self->{'_DBH'};
    $est_id = $self->_get_max_id('est') + 1;
    $seq_id = $self->_get_max_id('sequence') + 1;
    $sthEst = $dbh->prepare($gSQL{'insert_est'});
    $sthSequence = $dbh->prepare($gSQL{'insert_sequence' });
    $fastaRec=$self->nextFastaRec($fh);# Eat first '>'
    for(;$fastaRec=$self->nextFastaRec($fh);$est_id++,$seq_id++){
        $sthEst->execute($est_id, $seq_id, $fastaRec->{'id'});
        $raRows = $fastaRec->{'raRows'};
        $sthSequence->execute_array({},$seq_id,[0..$#{$raRows}],$raRows);
    }
    $fh->close() || TGI::Exception::IO->throw("Can not close $fName.");
}

=head2 load_asm_acel(file_Name)

 Will load the contigs found in the ACE file I<file_Name>. Will throw an exception in case something wrong happends.
 This should work in any DBMS. Override this with a bulk load method specific for your DBMS. You should fall back to this subroutine if an exception arise though.
    
=cut

sub load_asm_ace {
    my $self = shift;
    my $fName = shift;
    my ($fh,$rhContig,$asm_id,$seq_id,$dbh,$raEst);
    my ($sthAssembly, $sthSequence,$raSeqRows,$sthEstNames);
    $dbh = $self->{'_DBH'};
    $fh = IO::File->new($fName,'r');
    TGI::Exception::IO->throw("Can not open $fName.") if(not $fh);
                    $self->_reset_asm2est_temp();
        $asm_id = $self->_get_max_id('assembly') + 1;
    $seq_id  = $self->_get_max_id('sequence') + 1;
        $sthAssembly  = $dbh->prepare($gSQL{'insert_assembly'});
    $sthSequence = $dbh->prepare($gSQL{'insert_sequence'});
    $sthEstNames = $dbh->prepare($gSQL{'insert_est_names'});
        for(;$rhContig = $self->nextContig($fh);$asm_id++,$seq_id++){
                $sthAssembly->execute($asm_id,$seq_id,$rhContig->{'id'});
        $raSeqRows = $rhContig->{'raRows'};
        $sthSequence->execute_array({},$seq_id,[0..$#{$raSeqRows}],$raSeqRows);
                $raEst = $self->nextAFList($fh);
                TGI::Exception->throw("Sequence list for a Contig can not be empty (for contig : ".$rhContig->{'id'}.").") if(not $raEst);
         $sthEstNames->execute_array({},$asm_id,$raEst);
    }
        $dbh->do($gSQL{'insert_est_asm'});
        $fh->close() || TGI::Exception::IO->throw("Can not close the ACE file $fName.");
}

# Need to be sure we close the database connection. Some engines behave strange if we do not do so.
sub DESTROY {
   my ($self) = @_;
   $self->{_DBH}->disconnect() if($self->{_DBH});
}


1;
 



