# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentAppointmentCalendarManage;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CalendarObject = $Kernel::OM->Get('Kernel::System::Calendar');
    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');

    if ( $Self->{Subaction} eq 'New' ) {
        $LayoutObject->Block(
            Name => 'CalendarEdit',
            Data => {
                Subaction => 'StoreNew',
            },
        );
        $Param{Title} = $LayoutObject->{LanguageObject}->Translate("Add new Calendar");
    }
    elsif ( $Self->{Subaction} eq 'StoreNew' ) {

        # Get data
        my %GetParam;
        $GetParam{CalendarName} = $ParamObject->GetParam( Param => 'CalendarName' ) || '';
        $GetParam{ValidID}      = $ParamObject->GetParam( Param => 'ValidID' )      || '';

        my %Error;

        # Check name
        if ( !$GetParam{CalendarName} ) {
            $Error{'CalendarNameInvalid'} = 'ServerError';
        }
        else {
            # Check if user has already calendar with same name
            my %Calendar = $CalendarObject->CalendarGet(
                CalendarName => $GetParam{CalendarName},
                UserID       => $Self->{UserID},
            );

            if (%Calendar) {
                $Error{CalendarNameInvalid} = "ServerError";
                $Error{CalendarNameExists}  = 1;
            }
        }

        if (%Error) {
            $Param{Title} = $LayoutObject->{LanguageObject}->Translate("Add new Calendar");

            $LayoutObject->Block(
                Name => 'CalendarEdit',
                Data => {
                    %Error,
                    %GetParam,
                    Subaction => 'StoreNew',
                },
            );
            return _Mask(%Param);
        }

        # create calendar
        my %Calendar = $CalendarObject->CalendarCreate(
            %GetParam,
            UserID => $Self->{UserID},
        );

        if ( !%Calendar ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('System was unable to create Calendar!'),
                Comment => Translatable('Please contact the admin.'),
            );
        }

        # Redirect
        return $LayoutObject->Redirect(
            OP => "Action=AgentAppointmentCalendarManage",
        );
    }
    else {

        # get all user's calendars
        my @Calendars = $CalendarObject->CalendarList(
            UserID => $Self->{UserID},
        );

        $LayoutObject->Block(
            Name => 'AddLink',
            Data => {
            },
        );
        $LayoutObject->Block(
            Name => 'ExportLink',
            Data => {
            },
        );

        $LayoutObject->Block(
            Name => 'Overview',
            Data => {
            },
        );

        for my $Calendar (@Calendars) {
            $LayoutObject->Block(
                Name => 'Calendar',
                Data => {
                    %{$Calendar},
                },
            );
        }

        $Param{Title} = $LayoutObject->{LanguageObject}->Translate("Calendars");
    }

    return _Mask(%Param);
}

sub _Mask {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # output page
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentAppointmentCalendarManage',
        Data         => {
            %Param
        },
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

1;
