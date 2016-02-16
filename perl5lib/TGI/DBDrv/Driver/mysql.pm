=head1 TGI::DBDrv::Driver::mysql

 Interface to mysql.

=head1 VERSION

Version 0.01

=head1 FUNCTIONS

=cut 

package TGI::DBDrv::Driver::mysql;
use base qw ( TGI::DBDrv::Driver );
use strict; 
use DBI;
use TGI::Exception;

our $VERSION = '0.01';

my %gDDL_Create_Tables = (
    'sequence'      =>  q{create table sequence  (
                                id              integer
                              , row_no      integer
                              , seq_row     char(80)
                              , index        (id)
                              , index        (row_no)
                             ) ENGINE=InnoDB}
  , 'est'           =>  q{create table est (
                                id             integer
                              , seq_id      integer
                              , name       varchar(30)
                              , index       (id)
                              , index       (seq_id)
                              , index       (name)
                             ) ENGINE=InnoDB}
  , 'assembly'      =>  q{create table assembly (
                                id             integer
                              , seq_id      integer
                              , name       varchar(30)
                              , index       (id)
                              , index       (seq_id)
                            ) ENGINE=InnoDB}
  , 'asm_to_est'    =>  q{create table asm_to_est (
                                asm_id     integer
                              , est_id       integer
                              , index       (asm_id)
                              , index       (est_id)
                            ) ENGINE=InnoDB} 
);
my %gDDL_Create_Views = (
    'sequence_view'     =>   q{create or replace view sequence_view (id,seq) as
                                select id,group_concat(seq_row order by row_no asc separator '')
                                from sequence
                                group by id
                             }
  , 'est_view'          =>   q{create or replace view est_view (id,name,seq) as
                               select e.id, e.name, group_concat(s.seq_row order by s.row_no asc separator '')
                               from est e, sequence s
                               where e.seq_id = s.id
                               group by s.id
                             }
  , 'assembly_view'     =>   q{create or replace view assembly_view (id,name,seq) as
                               select a.id, a.name, group_concat(s.seq_row order by s.row_no asc separator '')
                               from assembly a, sequence s
                               where a.seq_id = s.id
                               group by s.id
                             }
  , 'singletons_view'   =>   q{create or replace view singletons_view (id,seq_id,name) as
                               select id,seq_id,name from est
                               where not exists (select * from asm_to_est where asm_to_est.est_id = est.id)
                             }                        
);
my %gDDL_Drop = (
    'sequence'    =>  q{drop table if exists sequence}
  , 'est  '       =>  q{drop table if exists est}
  , 'assembly'    =>  q{drop table if exists assembly}
  , 'asm_to_est'  =>  q{drop table if exists asm_to_est}        
);
my %gSQL = (
     'create_asm_to_est_temp'  =>  q{create temporary table asm_to_est_temp (
                                    asm_id        integer
                                  , est_name    varchar(30)
                                  , index         (asm_id)
                                  , index         (est_name)
                                 ) ENGINE=InnoDB}
  ,  'drop_est_asm_temp'       =>  q{drop table if exists asm_to_est_temp}
);

sub _Init {
    my ($self,$hParams) = @_;
    my $dbh;
    $dbh = DBI->connect("dbi:mysql:database=$hParams->{'-schema'};host=$hParams->{'-server'}",
                        $hParams->{'-user'}, $hParams->{'-pass'},
                        {RaiseError => 1, AutoCommit => 1 }
                        );
    $self->{'_DBH'} = $dbh;
}
=head2  reset()

Reset the entire schema. That is all the data will be lost since most probably this function
will drop and recreate the entire database schema.

=cut
sub reset  :locked :method {
    my $self = shift;
    my $dbh = $self->{'_DBH'};
    foreach my $Operations (\%gDDL_Drop, \%gDDL_Create_Tables, \%gDDL_Create_Views){
        foreach my $statement (keys %{$Operations}){
            $dbh->do($Operations->{$statement});
        }
    }
}

=head2 _reset_asm2est_temp()
Internal use only. This will reset the temporary asm_to_est table. This should vanish in the future.
 We need this for the safe load_asm_ace() method. Especially because at the moment we have no implementation for MySQL bulk load load_asm_ace() . We should think and test the possible use of mysqlimport utility.

=cut
sub _reset_asm2est_temp {
    my $self = shift;
    my $dbh = $self->{'_DBH'};
       $dbh->do($gSQL{'drop_est_asm_temp'});
    $dbh->do($gSQL{'create_asm_to_est_temp'});
}

=head1 COPYRIGHT & LICENSE

Copyright 2010 Valentin Antonescu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
 


