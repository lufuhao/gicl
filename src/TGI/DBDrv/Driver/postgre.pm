=head1 TGI::DBDrv::Driver::postgre

 Interface to postgresql.

=head1 VERSION

Version 0.01

=head1 FUNCTIONS

=cut 

package TGI::DBDrv::Driver::postgre;
use base qw ( TGI::DBDrv::Driver );
use strict; 
use DBI;
use TGI::Exception;

our $VERSION = '0.01';

my %gDDL_Create_Tables = (
    'sequence'      =>  q{create table sequence  (
                                  id        integer
                                , row_no    integer
                                , seq_row   char(80)
                             ) }
  , 'est'                =>  q{create table est (
                                  id        integer
                                , seq_id    integer
                                , name      varchar(30)
                             ) }
  , 'assembly'      =>  q{create table assembly (
                                  id        integer
                                , seq_id    integer
                                , name      varchar(30)
                            ) }
  , 'asm_to_est'    =>  q{create table asm_to_est (
                                  asm_id    integer
                                , est_id    integer
                            ) } 
);
my %gDDL_Create_Index = (
    'index_sequence_row_no'    => q{create index sequence_row_no       on sequence   (row_no)}
  , 'index_sequence_id'            => q{create index sequence_id               on sequence   (id)}
  , 'index_est_id'                      => q{create index idx_est_id                   on est             (id)}
  , 'index_est_seq_id'               => q{create index idx_est_seq_id             on est             (seq_id)}
  , 'index_est_name'                => q{create index idx_est_name              on est             (name)}
  , 'index_assembly_id'            => q{create index idx_assembly_id          on assembly    (id)}
  , 'index_assembly_seq_id'     => q{create index idx_assembly_seq_id    on assembly    (seq_id)}
  , 'index_asm_to_est'             => q{create index idx_asm_to_est_asm_id on asm_to_est (asm_id)}
  , 'index_asm_to_est'             => q{create index idx_asm_to_est_est_id  on asm_to_est (est_id)} 
);
my %gDDL_Create_Views = (
    'sequence_view'   =>     q{create or replace view sequence_view (id,seq) as
                                select id, array_to_string( array_agg( trim( seq_row )),'' )
                                from (select * from sequence order by id,row_no ) seqbyrowno
                                group by id
                              }
  , 'est_view'        =>     q{create or replace view est_view (id,name,seq) as
                               select e.id, e.name, sv.seq
                               from est e, sequence_view sv
                               where e.seq_id = sv.id
                             }
  , 'assembly_view'   =>     q{create or replace view assembly_view (id,name,seq) as
                               select a.id, a.name, sv.seq
                               from assembly a, sequence_view sv
                               where a.seq_id = sv.id
                             }
  , 'singletons_view' =>     q{create or replace view singletons_view (id,seq_id,name) as
                               select id,seq_id,name from est
                               where not exists (select * from asm_to_est where asm_to_est.est_id = est.id)
                             }                        
);
my %gSQL = (
                                         'select_user_tables' =>  q{select table_name from information_schema.tables
                                     where table_schema = 'public' and table_type='BASE TABLE'}
  ,  'select_user_views'  =>  q{select table_name from information_schema.tables
                                     where table_schema = 'public' and table_type='VIEW'}   
  ,  'drop_est_asm_temp'  =>  q{drop table if exists asm_to_est_temp cascade}
  ,  'create_asm_to_est_temp'  =>  q{create temporary table asm_to_est_temp (
                                     asm_id   integer
                                   , est_name varchar(30)
                                 ) }
  ,  'check_asm_to_est_temp'   => q{select table_name from user_tables where table_name='ASM_TO_EST_TEMP'}
  ,  'create_temp_index_asm_id'     =>  q{create index idx_tmp_est_id on asm_to_est_temp (asm_id)}
  ,  'create_temp_index_est_name' =>  q{create index idx_tmp_est_name on asm_to_est_temp (est_name)}
);

sub _Init {
    my ($self,$hParams) = @_;
    my $dbh;
    $dbh = DBI->connect("dbi:Pg:dbname=$hParams->{'-schema'};host=$hParams->{'-server'}",
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
    my($dbh,$arefTables,@Views);
    $dbh = $self->{'_DBH'};
        $arefTables = $dbh->selectall_arrayref($gSQL{'select_user_tables'});
    foreach my $row (@{$arefTables}){
        $dbh->do( 'drop table '.$row->[0].' cascade' );
    }
       foreach my $Op ( \%gDDL_Create_Tables, \%gDDL_Create_Index ){
        foreach my $statement (keys %{$Op}){
            $dbh->do($Op->{$statement});
        }
   }
      @Views = ('sequence_view','est_view','assembly_view','singletons_view');
   foreach my $this_view (@Views){
        $dbh->do($gDDL_Create_Views{$this_view});
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
 


