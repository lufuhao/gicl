
=head1 TGI::DBDrv

TGI::DBDrv - This is not quite a "driver" but only a simple way to separate the SQL and DB access from the main application.
 
=head1 SYNOPSIS

  use TGI::DBDrv;
  my $db = TGI::DBDrv->new({-user=>$user, -pass => $pass, -driver => $driver, -server => $server, -schema => $schema}); # will return a Oracle db object;
  # then ...
  $db->method();
  
=head1 DESCRIPTION

This is the only way TGICL should get a hold onto a DBMS driver. All the database operations are incapsulated into the driver.
 

=cut 

package TGI::DBDrv;
use strict;
use TGI::Exception;
our $VERSION = '0.01';

=head1 METHODS: 

=head2 new() - A factory here.

I<Input:> a hash with all the options. C<-user> is the username, C<-pass> is the password, C<-driver> means mostly what RDBMS you want to use (mysql, oracle, postgresql, etc...), C<server> is the database server. C<schema> is required in some rare situations. For example MySQL has a database concept. If you use MySQL you will need to provide here the MySQL database you are going to use. For Oracle you normally do not need this as long as you use the default user schema. In some situations you may have a user with rights into another schema. In this case you will need to provide the schema as well. 

I<Output:> A driver object.

I<Error:> Throws an Exception in case something goes wrong.

=cut
sub new {
    my ($classtype, $hParams)=@_; 
    my ($drv,$drvname);
    $drvname = "TGI::DBDrv::Driver::".(ref($hParams)?$hParams->{'-driver'}:$hParams);
    no strict "refs";
    eval  "use $drvname";
    if($@){
        TGI::Exception->throw("Can not load driver $drvname!");
    }
    $drv = $drvname->new({-user=>$hParams->{'-user'}, -pass => $hParams->{'-pass'},
                          -server => $hParams->{'-server'}, -schema => $hParams->{'-schema'}});
    return $drv;
}

1;

 


