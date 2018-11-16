
=head1 TGI::Exception

 TGI::Exception - A simple exception handling implementation.
 
=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use TGI::Exception;
    use strict;
    
    my $Big,$Rez,$Delta;
    
    eval {
        open FS,"<myfile"   or TGI::Exception::IO->throw();
        ($Big,$Delta) = <FS>;        
        $Rez = $Delta / $Big; 
    }
    if ($@){
        if(my $e = TGI::Exception::IO->caught()){
            print $e->GetMessage();
            print "Try to open another file\n";
        }
        elsif(TGI::Exception->caught(my $e = $@)){
            $e->rethrow();
        }
        else{
            die $@;
        }
    }
    

  
=head1 DESCRIPTION

I needed some fast and simple exception handling helpers. Be aware that the
stack trace doesn't necessary trace the entire stack. What I want most is to find the main problem that initiated the whole exception raising show, and this module does that in a fast and efficient way and the code is cleaner is easier to understand. 

=head1 FUNCTIONS

=cut 

package TGI::Exception;

use strict; 



use overload  '""' => sub { return shift->GetMessage(); };  
our $VERSION = '0.01';

my $Init = sub {
    my $self = shift;
    my $msg = shift;
    $self->{message} = [split(/\n/,$msg)]; 
};


=head2 new() - Package contructor.

I<Input:> $classtype, $error_msg

I<Error:> Dies in case $classtype is a reference.

I<Note:>

  You may never have the need to call this function explicitly. If you call it you probably wanted throw() or rethrow() instead.

=cut
sub new {
    my ($classtype, $msg)=@_; 
    my $self={};
    die("Can't use a reference for new! ") if(ref $classtype);
    bless($self, $classtype);
    $self->$Init($msg);
    return($self);
}



=head2 caught - Exception detection

I<Input:> $@ or null (It will read $@ anyway )

I<Error:> Dies in case it is called as a object method.

I<Returns:> The Exception Object in case an Exception object was detected or NULL otherwise.

I<Note:>

  This is a class only method. 

=cut

sub caught {
    my $self = shift;
                 my $Exception = shift || $@;
    return if(not ref($Exception));    return if(not UNIVERSAL::can($Exception,'isa'));     return $Exception if($Exception->isa($self));
}

=head2 GetMessage - Exception message retrival.

I<Input:> NULL

I<Returns:> Dumps the "error message stack". That is will return all the exception messages
stored in $self->{message} stack.

=cut

sub GetMessage {
    my $self = shift;
    local $" ="\n";
    return "@{$self->{message}}\n";
}

=head2 throw - The main method of raising an exception.

I<Input:> $msg - a descriptive exception message string.

I<Returns:> Dumps the "error message stack". That is will return all the exception messages
stored in $self->{message} array.

I<Note:>

  This is a class only method. 

=cut


sub throw
{
    my $self = shift;
    my $msg = shift || '';
    my ($package, $filename, $line);
                            
                        if($@){
                                    ($package, $filename, $line) = caller;
        $msg = "\nPackage $package, File $filename, Line $line == $msg";
        $msg .= " \n[ $self has been thrown ]";
                die $self->new("$@ " . $msg); 
    }
                for(my $i = 1;;$i++){
        ($package, $filename, $line) = caller($i);
        last if( not $package);
        $msg = "\nPackage $package, File $filename, Line $line == $msg";
    }
    $msg .= " \n[ $self has been thrown ]";
    die $self->new($msg); 
}

=head2 rethrow - Rethrow an exception

I<Input:> $msg - a descriptive exception message string.

I<Returns:> Dumps the "error message stack" exactly like throw(). 

I<Note:>

  This rethrows a previously raised exception. 

=cut
sub rethrow
{
    my $self = shift;
    my $msg = shift;
                    my ($package, $filename, $line) = caller;
    $msg = "\nRethrow (".ref($self).") : Package $package, File $filename, Line $line == $msg";
    push @{$self->{message}},$msg;
    die $self;
}




package TGI::Exception::IO;

use base qw( TGI::Exception );
use strict;


sub throw
{
    my $self = shift;
    my $msg = shift;
    $msg .= "\n=System Error: $!"  if($!);
    $msg .= "\n=OS Error: $^E"     if($^E);  
    $self->SUPER::throw($msg);
}


 package TGI::Exception::IPC;

use base qw( TGI::Exception );
use strict;


sub throw
{
    my $self = shift;
    my $msg = shift;
    $msg .= "\n=Child Status: $?" if($?);
    $msg .= "\n=System Error: $!"  if($!);
    $self->SUPER::throw($msg);
}


1;
=head1 BUGS and CAVEATS

Report bugs, complaints, comments or any UFO apparitions to us: compbio@jimmy.harvard.edu 

=head1 TODO:

Probably a nicer stack output would be welcomed, as well as some work to speed up the stack processing a little.
The IO and IPC expections could use some better error reporting formating.

=cut



