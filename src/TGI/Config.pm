
package TGI::Config;

=head1 NAME

 TGI::Config - A very simple implementation for Config files.
 
=head1 SYNOPSIS

I<Reading Configs>

  use TGI::Config;
  # open the config file and read some config values.
  $cfg = TGI::Config->new();
  if(!$cfg->open("myconfig.cfg")){
    die("cannot open config file.");
  }

  # Read a value from 'DEFAULT' section.
  $myvalue = $cfg->value(key=>MY_KEY); 
  # Read a value from a specific section.
  $myOther = $cfg->value(key=>MY_KEY,section=>MY_SECTION);  
  $refArray=$cfg->sections(); # Get all sections in the config.
  $refArray=$cfg->keys("MY_SECTION"); # All keys for 'MY_SECTION' section.
  @allKeys=$cfg->keys(); # All keys from 'DEFAULT' section.
  undef $cfg; # Release the config if you want.
  
I<Dynamically create Configs>  

  use TGI::Config;
  if(not $myCfg->create('config.cfg')){
    print("something wrong during creation...");
    print("maybe there is another file with the same name there");
    die("please check this is and try again.")
  }

  # set this key in the 'DEFAULT' section
  $cfg->value(key=>MY_KEY,value=>NEW_VALUE); 
  $cfg->delete("MY_KEY"); # Delete a key from 'DEFAULT' section.

  # set these keys in MY_SECTION section  
  $cfg->value(key=>MY_KEY,value=>NEW_VALUE,section=>MY_SECTION);
  $cfg->delete("MY_KEY","MY_SECTION");

  # Updating the config. This is gonna write down the config file. 
  $cfg->update(); 

I<Modifying Configs>  

  use TGI::Config;
  # open the config file and read some config values.
  $cfg = TGI::Config->new();
  if(!$cfg->open("myconfig.cfg")){
    die("cannot open config file.");
  }
  # Read a value from 'DEFAULT' section.
  $myvalue = $cfg->value(key=>MY_KEY); 
  $cfg->delete("MY_KEY"); # Delete a key from 'DEFAULT' section.
  # Add a new section MY_SECTION and a key in it.  
  $cfg->value(key=>MY_KEY,value=>NEW_VALUE,section=>MY_SECTION);

  # Updating the config. 
  $cfg->update(); 


=head1 DESCRIPTION

TGI::Config is a very simple config file interface. The file format is expected
to be in a KEY=VALUE format. Any other lines will be ignored. Please note that 
update() is the method who actually updates the external file.

Config files consists of sections and declarations. A declaration is in a form
of KEY = VALUE format. Sections are defined using square brackets. You can explicitly 
close a section [section] with [/section] or even [/] if you want. All identifiers 
are case sensitive. So section [Section] is not the same with [section]. Everything after 
the character # is ignored and considered a comment. 
If you want to include a # character into a name you have to escape it with '\' like in linux.

I<Config Files Examples:>

    # All definitions are placed by default in the 'DEFAULT' section.
     This line is gonna be ignored
     NUM_THDREADS = 43 # a comment

     # Next lines contain escaped characters
     # and they will be translated into
     # MY#WEIRD#NAME = MY#WEIRD#VALUE
     MY\#WEIRD\#NAME = MY\#WEIRD\#VALUE # another comment 
     # process name
     PRC = mydaemon


     [SECTION Example]
       A = 23
     [/SECTION Example] # Explicitly close this section
     
       A = 33 # This is placed again in section 'DEFAULT'.
     
     [Non Closed Section]
       B = 'peperoni and olives'
     [Another Section] # This automatically close the previous section.
       B = 'mushrooms and olives'
     [DEFAULT] # Explicitly open the 'DEFAULT' section.
       A = 44; # Overwrite the previous value of A 33 with 44.  
     [Non Closed Section] # Reopen this section
       C = 'just mushrooms' # Add a new entry.
       B = 'olives only' # Overwrite the previous B

=cut

use TGI::Exception;
use IO::File;
our $VERSION = '0.01';

my $Init = sub {
    $self = shift;
    $self->{"_SECTIONS"} = {};
    $self->{"_RAW_FILE"} = [];
    $self->{"_INDEX"} = [];
    $self->{"_UPDATED"} = 1;     $self->{"_FILE_NAME"}=undef;
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Input: File Handler
# Output: A reference to an array with all the file. Each row from
#       the array coresponds to a row in the file. Updates the
#       $self->{"_RAW_FILE"} variable.
# Error: returns undef.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $LoadConfig = sub {
    my ($self,$fh) = @_;
    return if(not $fh or (not defined($fh)));
    my $rawfs = [];
    local $/="\n";
     while(<$fh>){
         chomp;
         push(@{$rawfs},$_);
     }
    $self->{"_RAW_FILE"} = $rawfs;
    return $rawfs;
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Input: A string representing a Section Name. 
# Output: Returns a reference to a hash pointing to the requested Section.
# Error: Returns undef.
# Notes: If the given section name is not found a new one is created.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $Section = sub {
    my $self = shift;
    my $SectionName = shift;
    return if(not $self->{"_SECTIONS"});
    my $rhSections = $self->{"_SECTIONS"};
    $rhSections->{$SectionName}={} if(not exists($rhSections->{$SectionName}));
    return $rhSections->{$SectionName};
};
  
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Input: None. The Config file should be already loaded. 
# Output: Updates the  $self->{"_SECTIONS"} variable
# Error: Returns undef.
# Notes: It will parse the $self->{"_RAW_FILE"} and build the
#    $self->{"_SECTIONS"} from it.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $ParseConfig = sub {
    my $self = shift;
    return if(not $self->{"_FILE_NAME"}); 
    my $rawFile = $self->{"_RAW_FILE"};
    my ($rhCurrentSection,$i,$line,$raIndex);
    return if(not $rawFile);
    $raIndex = $self->{"_INDEX"};
    for($i=0;$i<=$#{$rawFile};$i++){
        $line = $rawFile->[$i];
        $line = substr($line,0,$-[0]+1) if($line =~/(?<!\\)#/);
        $line =~ s/\\//g;	
        # Check to see if this is a section.
        if($line =~ /\[\s*(.*?)\s*\]/){
            $line = $1;
            if($line =~ /^\//){ 
                $rhCurrentSection = undef; # A section is closed.
            }
            else{
                # Open a new section or append an old one.
                $rhCurrentSection = $self->$Section($line);
            }
            next;
        }
        # Check to see if this is a declaration.
        if($line =~ /^\s*(\S+?)\s*=\s*(.*?)\s*$/){
            if(not $rhCurrentSection){
                $rhCurrentSection = $self->$Section("DEFAULT");
            }
            $rhCurrentSection->{$1}=[$2,$i];
            $raIndex->[$i] = $rhCurrentSection->{$1};
        }
        # Ignore other kind of text lines.
    }
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Input: (<row_idx>,<Old_Str>,<New_Str>). 
# Output: Updates the  $self->{"_RAW_FILE"} variable.
# Error: Returns undef.
# Notes: It will replace the <Old_Str> from $self->{"_RAW_FILE"}
#       at index <row_idx> with the new <New_Str>.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $ChangeVal = sub {
    my $self = shift;
    return if(not $self->{"_FILE_NAME"});
    return if(scalar(@_)<3);
    my ($idx,$strOld,$strNew) = @_;
    my $rawFile = $self->{"_RAW_FILE"};
    return if(not $rawFile);
    my $LastIdx = $#{@{$rawFile}};
    return if($LastIdx == -1);
    return if($idx>$LastIdx);
    $rawFile->[$idx] =~ /=/;
    substr($rawFile->[$idx],$+[0]) =~ s/$strOld/$strNew/;
    $self->{"_UPDATED"} = 0;
    return $strOld;
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Input: (<row_idx>). 
# Output: True.
# Error: Returns undef.
# Notes: It will remove the <idx> row from $self->{"_RAW_FILE"}.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $RemoveRow = sub {
    my $self = shift;
    return if(not $self->{"_FILE_NAME"});
    my $idx = shift;
    return if(not $idx);
    my ($raRawFile,$LastIdx,$raIndex,$i,$raRecord);
    $raRawFile = $self->{"_RAW_FILE"};
    $LastIdx = $#{@{$raRawFile}};
    return if($idx<0 or $idx>$LastIdx);
    @{$raRawFile}=(@{$raRawFile}[0..$idx-1],@{$raRawFile}[$idx+1..$LastIdx]);
    $raIndex = $self->{"_INDEX"};
    @{$raIndex} = (@{$raIndex}[0..$idx-1],@{$raIndex}[$idx+1..$#{@{$raIndex}}]);
    for($i=$idx;$i<=$#{@{$raIndex}};$i++){
       next if(not $raIndex->[$i]); 
       $raRecord = $raIndex->[$i];
       $raRecord->[1]--; 
    }
    $self->{"_UPDATED"} = 0;
    return 1;
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Input: (<section>). 
# Output: Returns the last index in $self->{"_RAW_FILE"} for the
#       given <section>.
# Error: Returns undef.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $LastIdx = sub {
    my $self = shift;
    return if(not $self->{"_FILE_NAME"});
    my $sectionKey = shift;
    return if(not $sectionKey);
    my ($raRawFile,$LastIdx,$rhSection,$k,$idx);
    $raRawFile = $self->{"_RAW_FILE"};
    $rhSection = $self->{"_SECTIONS"}->{$sectionKey}; 
    foreach $k (keys %{$rhSection}){
        $idx = $rhSection->{$k}->[1];
        $LastIdx = $idx if($idx > $LastIdx);
    }
    return($LastIdx);
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Input: (<key>,<value>,[<section>]). 
# Output: Returns the index where the new row has been added.
# Error: Returns undef.
# Notes: It will append to the $self->{"_RAW_FILE"} the given value, 
#       creating if necessary the section for it.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $AddRawValue = sub {
    my $self = shift;
    return if(not $self->{"_FILE_NAME"});
    my ($raRawFile,$InsertIdx,$key,$value,$sectionKey,$rhTargetSection);
    $key = shift || return;
    $value = shift || return;
    $sectionKey = shift || 'DEFAULT';
    $raRawFile = $self->{"_RAW_FILE"}; 
    $rhTargetSection = $self->$Section($sectionKey);
    if(scalar(keys(%{$rhTargetSection}))==0){
        push(@{$raRawFile},'['.$sectionKey.']');
        push(@{$raRawFile},'_');
        $InsertIdx = $#{@{$raRawFile}};
    }
    else{ 
        $InsertIdx = $self->$LastIdx($sectionKey);
        @{$raRawFile} = (@{$raRawFile}[0..$InsertIdx],'_',@{$raRawFile}[$InsertIdx+1..$#{@{$raRawFile}}]);
        $InsertIdx++;
    }
    $raRawFile->[$InsertIdx] = $key.' = '.$value;
    $self->{"_UPDATED"} = 0;
    return($InsertIdx);
};

=head1 METHODS: 

=head2 new([<Config File Name>]) - Package contructor.

I<Input:> A config file filename (optional).

I<Output:> Will return an TGI::Config Object.

I<Error:> Dies in case it cannot open the given configuration file.

I<Example:>
        
        # Will die in case of error.
        $myCfg = TGI::Config->new('myfile.cfg'); 
        # Will return a Config object.
        $newCfg = TGI::Config->new();
        # Probably you may want to do something like this
        eval { $cfg = TGI::Config->new('my_ubber.cfg');};
        if($@){print("Sorry, I can not open this config file!");}

=cut
sub new {
    my ($classtype,$fname) = @_;
    my $self = {};
    bless($self, ref($classtype) || $classtype || "TGI::Config");
    $self->$Init();
        $self->open($fname);
    return($self);
}

=head2 open(<Config File Name>)

I<Input:> A valid File Name for the config to open.

I<Output:> The name of the config.

I<Error:> Returns undef in case of error.

I<Notes:> This function is the prefered method of initializing a Config
File since the main program can resolve the errors that can appear.

I<Example:>

        eval {$myCfg->open('config.cfg'))};
        if($@){print("Can not open this config file!")}
            # ... Do something here ...
        

=cut
sub open {
    return if(!(@_==2));
    my ($self,$CfgName) = @_;
    return if(!$self);
    return if(! -e $CfgName);
    return if(!ref($self));
eval{
        my $fh = IO::File->new($CfgName,"r");
        TGI::Exception::IO->throw("Can not open for reading the file $CfgName !") if(!$fh);
        $self->$Init();
        $self->$LoadConfig($fh);
        $self->{"_FILE_NAME"}= $CfgName;
        $self->$ParseConfig();
        $fh->close();
        $self->{"_UPDATED"} = 1;
    };
    if($@){
        if(my $e = TGI::Exception::IO->caught()){
            $e->rethrow();
        }
        else{
            TGI::Exception::IO->throw("IO exception while accessing the config file $CfgName  ! ");
        }
    }
    return($CfgName);
}

=head2 create(<Config File Name>)

I<Input:> A valid File Name for the config creation.

I<Output:> The name of the config.

I<Error:> Returns undef in case of error.

I<Notes:> This function will initialize the Config Object. No external file
is created in this stage. If you want the file to be saved make sure you
call Update() before leaving the program.

I<Example:>

       eval { $myCfg->create('config.cfg'); };
       if($@){print("Can not create a new Config");}

=cut
sub create {
    my ($self,$CfgName) = @_;
    TGI::Exception->throw("Invalid parameters for create().")  if(!(@_==2) || !ref($self));
    TGI::Exception::IO->throw("$CfgName already exists! ") if(-e $CfgName);
    $self->$Init();
    $self->{"_FILE_NAME"}= $CfgName;
    return($self);
}


=head2 value(<Hash>)

I<Input:> A Hash of parameters as follows:

=over 5

=item B<key> - A string value for the key.

=item B<value> - The value you wish to set for the given key.

=item B<section> - Section from where the key belongs to.

=back 

I<Output:> The requested value for the given key.

I<Error:> Returns undef.

I<Notes:> The only mandatory parameter is B<key>. In case B<section> is missing
the 'DEFAULT' section is assumed by default. If B<value> is missing the function
will try to return the value for the given B<key>. If value is present then the
B<key> will be set to the given value and it will create a new section/key if the
ones provided doesn't exists.

I<Example:>

        # Will read the 'MaxThreads' key from 'DEFAULT' section.
        $MaxThreads = $myCfg->value(key=>MaxThreads);
        # Will read the 'MaxThreads' key from 'Child Process' section.
        $ChildMaxThreads = $myCfg->value(key=>MaxThreads,section=>'Child Process');
        # Will set the value for 'MaxThreads' key in the'DEFAULT' section. 
        $myCfg->value(key=>MaxThreads,value=10);


=cut
sub value {
    my $self = shift;
    return if(not $self);
    return if(not ref($self));
    my %param = @_;
    return if(not exists($param{'key'}));
    return if(not $self->{"_FILE_NAME"});
    my ($sections,$key,$sectionKey,$value,$rhSection,$idx);
    $sections = $self->{"_SECTIONS"};
    return if(not $sections);
    $key = $param{'key'};
    if(exists($param{'section'})){
        $sectionKey = $param{'section'};
    }
    else{
        $sectionKey = 'DEFAULT';
    }
    if(exists($param{'value'})){
        $rhSection = $self->$Section($sectionKey); 
        if(exists($rhSection->{$key})){
            $self->$ChangeVal($rhSection->{$key}->[1],$rhSection->{$key}->[0],$param{'value'});
            $rhSection->{$key}->[0] = $param{'value'};
        }
        else{
            $idx = $self->$AddRawValue($key,$param{'value'},$sectionKey);
            $rhSection->{$key} = [$param{'value'},$idx]; 
            $self->{"_INDEX"}->[$idx] = $rhSection->{$key};
        }
        return $param{'value'};
    }
    return if(not exists($sections->{$sectionKey}));
    $rhSection = $sections->{$sectionKey};
    return if(not exists($rhSection->{$key}));
    return $rhSection->{$key}->[0];	
}


=head2 keys([<Section Name>])

I<Input:> An optional Section Name string.

I<Output:> An reference to an array.

I<Error:> Returns a reference to an array with all the keys from the given section.
If no section is given the 'DEFAULT' is assumed.

I<Example:>

          # Get all the keys for DEFAULT
          $refArray = $myCfg->keys();
          # Get all the keys for 'SECTION' section.
          $refArray = $myCfg->keys('SECTION');
          # Do something with @{$refArray} ...
          

=cut
sub keys {
    my $self = shift;
    return if(!$self);
    return if(not ref($self));
    my ($sections,$key,$sectionKey,$value,$rhSection);
    $sections = $self->{"_SECTIONS"};
    return if(not $sections);
    return if(!$self->{"_FILE_NAME"});
    $sectionKey = shift || 'DEFAULT';
    return if(not exists($sections->{$sectionKey}));
    $rhSection = $sections->{$sectionKey};
    return [keys %{$rhSection}];
}

=head2 sections()

I<Input:> None.

I<Output:> A reference to an array.

I<Error:> Returns a reference to an array with all the sections in the current config.

I<Example:>

          # Get all the sections
          $refArray = $myCfg->sections();
          

=cut
sub sections {
    my $self = shift || return;
    return if(!$self);
    return if(not ref($self));
    return if(!$self->{"_FILE_NAME"});
    return [CORE::keys %{$self->{"_SECTIONS"}}];
}


=head2 delete(<key>,[<Section>])

I<Input:> The key you want to delete and the section where the key belongs.

I<Output:> Returns the value of the deleted key

I<Error:> undef.

I<Notes:> Like in all cases, in case no <Section> is provided the 'DEFAULT'
section is assumed to be the target of delete request.

I<Example:>

          # Delete from 'DEFAULT'
          $OldValue = $myCfg->delete('myKey');
          # Delete from section 'Section'
          $OldValue = $myCfg->delete('myKey','Section');
          

=cut
sub delete {
    my $self = shift;
    return if(!$self);
    return if(not ref($self));
    return if(!$self->{"_FILE_NAME"});
    my $key = shift;
    return if(not $key);
    my ($sectionKey,$rhSections,$rhTargetSection,$OldVal,$idx);
    $sectionKey = shift || 'DEFAULT';
    $rhSections = $self->{"_SECTIONS"};
    return if(not exists($rhSections->{$sectionKey}));
    $rhTargetSection = $rhSections->{$sectionKey};   
    return if(not exists($rhTargetSection->{$key}));
    $OldVal = $rhTargetSection->{$key}->[0];
    $idx = $rhTargetSection->{$key}->[1];
    delete($rhTargetSection->{$key});
    $self->$RemoveRow($idx);
    return $OldVal;
}

=head2 update()

I<Input:> None.

I<Output:> Returns the name of the file.

I<Error:> Dies in case of error.

I<Notes:> You have to call this function to be sure that all the modifications you made
are written to the external file.

I<Example:>

          $myCfg->update();

=cut
sub update {
    my $self = shift;
    return if(!$self);
    return if(not ref($self));
    my ($key,$content,$CfgName,$fh,$fName,$raRawFile,$line);
    return if(!$self->{"_FILE_NAME"});
    $fName = $self->{"_FILE_NAME"};
    eval{
        $fh = IO::File->new($fName, "w");
        TGI::Exception::IO->throw ("Cannot create the $fName file!") if(!$fh);
        $raRawFile = $self->{"_RAW_FILE"};
        foreach $line (@{$raRawFile}){
            $fh->print($line,"\n");
        }
        $fh->close();
        $self->{"_UPDATED"} = 1;
    };
    if($@){
        TGI::Exception::IO->throw("IO exception while updating $fName file !");
    }
}

sub DESTROY {
    my $self = shift;
    $self->update() if(not $self->{"_UPDATED"});
}

1;

=head1 BUGS and CAVEATS

I<Multiple Key Declaration>

It is not a good practice to redefine keys inside a config file. The module will take 
into account tha last definition encountered. If you try to modify that key
or to delete the key from inside a perl script, the module will act only on the 
considered key. For example in case you have:

 KEY_1 = 44
 KEY_1 = 66
 
 
Only the 66 value will be considered. Furthermore, if you try the following sequence:

 $cfg->delete('KEY_1');
 $cfg->update();
 
The configuration file will be:

 KEY_1 = 44
 
You have erased only the last value for that key and not all the apparitions of it
in the file. 
  
  

Report bugs, complaints, comments or any UFO apparitions to us: compbio@jimmy.harvard.edu 

=cut
