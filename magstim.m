% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

classdef magstim < handle
    properties %(SetAccess = private)
        portID;
        port =[];
        connected = 0; %Default value of connected set to 0 to make sure the user connects the port
        communicationTimer = [];
    end
    
    methods 
        function self = magstim(PortID)
            % PortID <char> defines the serail port id on your computer
           
            %% Find All Available Serial Ports On Your Computer
            foundPorts = instrhwinfo('serial');
            listOfComPorts = foundPorts.AvailableSerialPorts;
            
            %% Check Input Validity:
            if nargin < 1
                error('Not Enough Input Arguments');
            end
            if ~(ischar(PortID))
                error('The Serial Port ID Must Be a Character Array');
            end
            if ~any(strcmp(listOfComPorts,PortID))
                error('Invalid Serial Com Port ID');
            end
            
            self.portID = PortID;
        end
       
        %% Opening The Desired Port
        function [errorOrSuccess, deviceResponse] = connect(self)
            %% Check Input Validity
            if nargin < 1
            	error('Not Enough Input Arguments');
            end
            % Create the port if doesn't already exist. We do this here
            % because if we disconnect we want to be able to re-connect
            % using the same object
            if isempty(self.port)
                self.port = serial(self.portID);
                self.port.BaudRate = 9600;
                self.port.DataBits = 8;
                self.port.Parity = 'none';
                self.port.StopBits = 1;
                self.port.Terminator = '';
                self.port.Timeout = 0.3;
            end
            
            %% Open The Port
            if strcmp(self.port.Status, 'open')
                errorOrSuccess = 0;
                deviceResponse = 'Already Connected To Magstim';
                return
            else
                fopen(self.port);
            end
            %% Try and Connect
            [errorOrSuccess, deviceResponse] = self.remoteControl(1, 1);
            if errorOrSuccess > 0
                % Couldn't connect, so call disconnect to delete the
                % connection. This will allow us to try again
                self.disconnect()
                error('Could not connect to the magstim');
            else
                self.connected = 1;
            end
        end
   
        %% Closing The Desired Port
        function [errorOrSuccess, deviceResponse] = disconnect(self)
        %% Check Input Validity
            if nargin < 1
            	error('Not Enough Input Arguments');
            end
            %% Close The Port
            if ~isempty(self.port) && strcmp(self.port.Status, 'open')
                % If connected, disarm and tell magstim we're relinquishing control
                if self.connected == 1
                    [~, deviceResponse]= self.remoteControl(0, 1);
                end
                fclose(self.port);
            end
            % Delete and erase the port connection
            delete(self.port);
            self.port = [];
            self.connected = 0;
            errorOrSuccess = 0;
        end
        
        function [errorOrSuccess, deviceResponse] = setAmplitudeA(self, power, varargin)
            % Inputs:
            % power<double> : is the desired power amplitude for stimulator A
            % varargin<bool> refers to getResponse<bool> that can be True (1) or False (0)
            % indicating whether a response from device is required or not.
            % The default value is set to false.

            % Outputs:
            % DeviceResponse: is the response that is sent back by the
            % device to the port indicating current information about the device
            % errorOrsuccess: is a boolean value indicating succecc = 0 or error = 1
            % in performing the desired task

            %% Check Input Validity:
            if nargin < 2
                error('Not Enough Input Arguments');
            end
            if nargin < 3
                getResponse = false ; %Default Value Set To 0
            else
                getResponse = varargin{1};
            end
            if (getResponse ~= 0 && getResponse ~= 1 )
                error('getResponse Must Be A Boolean');
            end
            if ~(isnumeric(power))|| rem(power,1)~=0
                error('power Must Be A Whole Number');
            end
            if (power < 0 || power > 100)
                error('power Must Be A Positive Value Less Than Or Equal To 100');
            end             
            if length(power) > 1
                error('Invaid Power Amplitude. It Must Be A Single Numeric');
            end

            %% Create Control Command
            
            [errorOrSuccess, deviceResponse] = self.processCommand(['@' sprintf('%03s',num2str(power))], getResponse, 3);

            end
        
        function [errorOrSuccess, deviceResponse] = arm(self, varargin)
            % Inputs:
            % varargin<bool> refers to getResponse<bool> that can be True (1) or False (0)
            % indicating whether a response from device is required or not.
            % The default value is set to false.

            % Outputs:
            % DeviceResponse: is the response that is sent back by the
            % device to the port indicating current information about the device
            % errorOrsuccess: is a boolean value indicating succecc = 0 or error = 1
            % in performing the desired task

            %% Check Input Validity:
            if nargin < 1
                error('Not Enough Input Arguments');
            end
            if length(varargin) > 1
                error('Too Many Input Arguments');
            end
            if nargin < 2
                getResponse = false ;
            else
                getResponse = varargin{1};
            end
            if (getResponse ~= 0 && getResponse ~= 1 )
                error('getResponse Must Be A Boolean');
            end

            %% Create Control Command
            [errorOrSuccess, deviceResponse] =  self.processCommand('EB', getResponse, 3);          
            end
        
        function [errorOrSuccess, deviceResponse] = disarm(self, varargin)
            % Inputs:
            % varargin<bool> refers to getResponse<bool> that can be True (1) or False (0)
            % indicating whether a response from device is required or not.
            % The default value is set to false.

            % Outputs:
            % DeviceResponse: is the response that is sent back by the
            % device to the port indicating current information about the device
            % errorOrsuccess: is a boolean value indicating succecc = 0 or error = 1
            % in performing the desired task

            %% Check Input Validity:
            if nargin < 1
                error('Not Enough Input Arguments');
            end
            if length(varargin) > 1
                error('Too Many Input Arguments');
            end
            if nargin < 2
                getResponse = false ;
            else
                getResponse = varargin{1};
            end

            if (getResponse ~= 0 && getResponse ~= 1 )
                error('getResponse Must Be A Boolean');
            end
            %% Create Control Command
            [errorOrSuccess, deviceResponse] =  self.processCommand('EA' ,getResponse, 3);
            end
        
        function [errorOrSuccess, deviceResponse] = fire(self, varargin)
            % Inputs:
            % varargin<bool> refers to getResponse<bool> that can be True (1) or False (0)
            % indicating whether a response from device is required or not.
            % The default value is set to false.

            % Outputs:
            % DeviceResponse: is the response that is sent back by the
            % device to the port indicating current information about the device
            % errorOrsuccess: is a boolean value indicating succecc = 0 or error = 1
            % in performing the desired task

            %% Check Input Validity
            if nargin < 1
                error('Not Enough Input Arguments');
            end
            if length(varargin) > 1
                error('Too Many Input Arguments');
            end
            if nargin < 2
                getResponse = false ;
            else
                getResponse = varargin{1};
            end
            if (getResponse ~= 0 && getResponse ~= 1 )
                error('getResponse Must Be A Boolean');
            end
            %% Create Control Command       
            [errorOrSuccess, deviceResponse] =  self.processCommand('EH', getResponse, 3);
            end
       
        function [errorOrSuccess, deviceResponse] = remoteControl(self, enable, varargin)
            % Inputs:
            % enable<boolean> is a boolean that can be True(1) to
            % enable and False(0) to disable the device
            % varargin<bool> refers to getResponse<bool> that can be True (1) or False (0)
            % indicating whether a response from device is required or not.
            % The default value is set to false.
            
            % Outputs:
            % deviceResponse: is the response that is sent back by the
            % device to the port indicating current information about the device
            % errorOrSuccess: is a boolean value indicating succecc = 0 or error = 1
            % in performing the desired task
            
            %% Check Input Validity
            if nargin < 2
            	error('Not Enough Input Arguments');
            end
            if length(varargin) > 1
            	error('Too Many Input Arguments');
            end
            if nargin < 3
            	getResponse = false;
            else
            	getResponse = varargin{1};
            end
               
            if (enable ~= 0 && enable ~= 1 )
                error('enable Must Be A Boolean');
            end
            if (getResponse ~= 0 && getResponse ~= 1 )
                error('getResponse Must Be A Boolean');
            end
           
            %% Create Control Command 
            if enable %Enable
                commandString = 'Q@';
            else %Disable
                commandString = 'R@';
                % Attempt to disarm the stimulator
                self.disarm();
            end
            
            [errorOrSuccess, deviceResponse] =  self.processCommand(commandString, getResponse, 3);
            if ~errorOrSuccess
                self.connected = enable;
                if enable
                    self.enableCommunicationTimer()
                else
                    self.disableCommunicationTimer()
                end
            end
        end
        
        function [errorOrSuccess, deviceResponse] = getParameters(self)  
        % Outputs:
        % DeviceResponse: is the response that is sent back by the
        % device to the port indicating current information about the device
        % errorOrsuccess: is a boolean value indicating succecc = 0 or error = 1
        % in performing the desired task
            
        %% Check Input Validity
        if nargin < 1
        	error('Not Enough Input Arguments');
        end
          
        %% Create Control Command
        [errorOrSuccess, deviceResponse] =  self.processCommand('J@', true, 12);
        end
        
        function [errorOrsuccess, DeviceResponse] = getTemperature(self)  
            % Outputs:
            % DeviceResponse: is the response that is sent back by the
            % device to the port indicating current information about the device
            % errorOrsuccess: is a boolean value indicating succecc = 0 or error = 1
            % in performing the desired task
            
            %% Check Input Validity
            if nargin <1
            	error('Not Enough Input Arguments');
            end
            
            %% Create Control Command
            [errorOrsuccess, DeviceResponse] =  self.processCommand('F@', true, 9);
        end
        
        function poke(self, loud)
        	% Inputs:
            % loud<bool>: determines whether or not to send (True=1) or
            % not send (False=0) an enable remote control command while
            % poking
            
            %% Check Input Validity 
            if nargin<2
            	loud = 0;
            end
                
            if (loud ~= 0 && loud ~= 1 )
            	error('send Parameter Must Be A Boolean');
            end 
                 
            if loud == 1
            	self.remoteControl(1,0)
            end
            stop(self.communicationTimer) 
            start(self.communicationTimer)
        end
        
        function pause(self, delay)
            % Inputs:
            % delay <double>: determines the duration of time for which 
            % matlab is paused while maintaining communication via serial COM port

            if nargin<2
                error('Not Enough Input Arguments');
            end
            if ~isnumeric(delay)|| length(delay)>1 || delay<0
                error('The Delay Time Must Be A Single Positive Number');
            end
            
            nextHundredth = 0;
            tic; 
            elapsed = 0.0;
            while elapsed <= delay
                    elapsed = toc;
                    if ceil(elapsed / 0.1) > nextHundredth 
                        % ceil instead of floor guarantees execution on first iteration and thus also for pauses < 0.1 s            
                        self.remoteControl(1, 0);
                        nextHundredth = nextHundredth + 1;
                    end
            end

        end 
        
        
    end
    
    methods (Access = 'protected')
        %%
        function maintainCommunication(self)
        	fprintf(self.port, 'Q@n');    
            fread(self.port, 3);
        end
        
        function enableCommunicationTimer(self)
            if isempty(self.communicationTimer)
                self.communicationTimer = timer;
                set(self.communicationTimer, 'ExecutionMode', 'fixedRate');
                set(self.communicationTimer, 'TimerFcn', @(~,~)self.maintainCommunication);
                set(self.communicationTimer, 'StartDelay', 0.5);
                set(self.communicationTimer, 'Period', 0.5);
            end
            % Start the timer
            if (strcmp(self.communicationTimer.Running, 'off')) 
                start(self.communicationTimer); 
            end
        end
        
        function disableCommunicationTimer(self)
            if ~isempty(self.communicationTimer)
                if strcmp(get(self.communicationTimer,'Running'),'on')
                    stop(self.communicationTimer);
                end
                delete(self.communicationTimer);
                self.communicationTimer = [];
            end   
        end
        
        function [errorOrSuccess, deviceResponse] = processCommand(self, commandString, getResponse, bytesExpected)
            %% Check If Port Is Connected
            % Or is a command does not require remote control
            if (self.connected == 0) && ~ismember(commandString(1),['Q','R','J','F','\']) && ~strcmp(commandString, 'EA')
                error ('You Need To First Connect The Port');
            end
            % Stop the timer (if we've already started it) and clear the port
            if ~isempty(self.communicationTimer)
                stop(self.communicationTimer)
            end
            flushinput(self.port)
                
            %% Send the command string
            fprintf(self.port, [commandString magstim.calcCRC(commandString)]); 
            
            % Read the first character in the response from the stimulator
            commandAcknowledge = char(fread(self.port, 1));
            if isempty(commandAcknowledge)
                errorOrSuccess = 1;
                deviceResponse = 'No response detected from device.';
            elseif strcmp(commandAcknowledge,'?')
                errorOrSuccess = 2;
                deviceResponse = 'Invalid command';
            elseif strcmp(commandAcknowledge,'N')
                readData = '';
                while true
                    characterIn = char(fread(self.port, 1));
                    if characterIn == 0
                        readData = [readData characterIn char(fread(self.port, 1))];
                        break
                    else
                        readData = [readData characterIn];
                    end
                end
                errorOrSuccess = 0;
                deviceResponse = self.parseResponse(commandAcknowledge, readData);
            else 
                readData = char(fread(self.port, bytesExpected - 1));
                if length(readData) < (bytesExpected - 1)
                    errorOrSuccess = 3;
                    deviceResponse = 'Incomplete response from device.';
                elseif strcmp(readData(1),'?')
                    errorOrSuccess = 4;
                    deviceResponse = 'Supplied data value not acceptable.';
                elseif strcmp(readData(1),'S')
                    errorOrSuccess = 5;
                    deviceResponse = 'Command conflicts with current device settings.';
                elseif readData(end) ~= magstim.calcCRC([commandAcknowledge readData(1:end-1)'])
                    errorOrSuccess = 6;
                    deviceResponse = 'CRC does not match message contents.';
                elseif getResponse
                    % Creating Output
                    errorOrSuccess = 0;
                    deviceResponse = self.parseResponse(commandAcknowledge, readData);
                else
                    errorOrSuccess = 0;
                    deviceResponse = [];
                end   
            end
            % Only restart the timer if we're: 1) connected to the magstim,
            % 2) the timer exists, and 3) we're not disabling remote control
            if self.connected && ~isempty(self.communicationTimer) && ~strcmp(commandString(1), 'R')
                start(self.communicationTimer)  
            end
        end
        
        %%
        function info = parseResponse(self, command, readData)
            %% Getting Instrument Status (always returned)
            statusCode = bitget(double(readData(1)),1:8);
            info = struct('InstrumentStatus',struct('Standby',             statusCode(1),...
                                                    'Armed',               statusCode(2),...
                                                    'Ready',               statusCode(3),...
                                                    'CoilPresent',         statusCode(4),...
                                                    'ReplaceCoil',         statusCode(5),...
                                                    'ErrorPresent',        statusCode(6),...
                                                    'ErrorType',           statusCode(7),...
                                                    'RemoteControlStatus', statusCode(8)));
                 
            %% Getting All Information
            %Get commands
            if command == 'J' %getParameters
                info.PowerA = str2double(char(readData(2:4)));
            elseif command == 'F'  %getTemperature
                info.CoilTemp1 = str2double(char(readData(2:4))) / 10;
                info.CoilTemp2 = str2double(char(readData(5:7))) / 10;
            end
        end
    end
    
    methods (Static)
        %%     
        function checkSum = calcCRC(commandString) % CRC checksum calculation
            % Sum command string, truncate to 8 bits, invert, and then
            % return as character array
            checkSum = char(bitcmp(bitand(sum(double(commandString)),255),'uint8'));
        end
       
    end
end
