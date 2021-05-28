classdef (Sealed, CaseInsensitiveProperties=true, TruncatedProperties=true) webcam < matlab.mixin.CustomDisplay & dynamicprops
    %WEBCAM Creates webcam object to acquire frames from your Webcam.
    %    CAMOBJ = WEBCAM returns a webcam object, CAMOBJ, that acquires images
    %    from the specified Webcam. By default, this selects the first
    %    available Webcam returned by WEBCAMLIST.
    %
    %    CAMOBJ = WEBCAM(DEVICENAME) returns a webcam object, CAMOBJ, for
    %    Webcam with the specified name, DEVICENAME. The Webcam name can be
    %    found using the function WEBCAMLIST.
    %
    %    CAMOBJ = WEBCAM(DEVICEINDEX) returns a webcam object, CAMOBJ, for
    %    Webcam with the specified device index, DEVICEINDEX. The Webcam device
    %    index is the index into the cell array returned by WEBCAMLIST.
    %
    %    CAMOBJ = WEBCAM(..., P1, V1, P2, V2,...) constructs the webcam object,
    %    CAMOBJ, with the specified property values. If an invalid property
    %    name or property value is specified, the webcam object is not created.
    %
    %    Creating WEBCAM object obtains exclusive access to the Webcam.
    %
    %    SNAPSHOT method syntax:
    %
    %    IMG = snapshot(CAMOBJ) acquires a single frame from the Webcam.
    %
    %    [IMG, TIMESTAMP] = snapshot(CAMOBJ) returns the frame, IMG, and the
    %    acquisition timestamp, TIMESTAMP.
    %
    %    WEBCAM methods:
    %
    %    snapshot     - Acquire a single frame from the Webcam.
    %    preview      - Activate a live image preview window.
    %    closePreview - Close live image preview window.
    %
    %    WEBCAM properties:
    %
    %    Name                 - Name of the Webcam.
    %    Resolution           - Resolution of the acquired frame.
    %    AvailableResolutions - Cell array of list of available resolutions.
    %
    %    The WEBCAM interface also supports the dynamic properties of the Webcam
    %    that we can access programmatically. Some of these dynamic properties
    %    are Brightness, Contrast, Hue, Exposure etc. The presence of these
    %    properties in the WEBCAM object depends on the Webcam that you connect
    %    to. Dynamic properties are not supported when using webcam in MATLAB
    %    Online.
    %
    %    Example:
    %       % Construct a webcam object
    %       camObj = webcam;
    %
    %       % Preview a stream of image frames.
    %       preview(camObj);
    %
    %       % Acquire and display a single image frame.
    %       img = snapshot(camObj);
    %       imshow(img);
    %
    %    See also WEBCAMLIST
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties(Dependent, GetAccess = public, SetAccess = private)
        %Name Specifies the name of the Webcam.
        %   The Name property cannot be modified once the object is created
        %   and is read only.
        Name
    end
    
    properties(Access=private)
        webcamImpl
    end
    
    properties(Dependent, GetAccess = public, SetAccess = private)
        AvailableResolutions
    end
    
    properties(Dependent)
        Resolution
    end
    
    methods(Hidden,Access=public)
        function webcamController = getCameraController(obj)
            % Return the controller for the current implementation of webcam
            webcamController = obj.webcamImpl.getCameraController;
        end
    end
    
    methods(Hidden)
        function obj = webcam(varargin)
            % Create a webcamDesktop object or webcamOnline object based on
            % where this is running. Also add dynamic properties if this is
            % a webcamDesktop object.
            try
                if ~matlab.webcam.internal.Utility.isMATLABOnline
                    obj.webcamImpl = matlab.webcam.internal.webcamDesktop(varargin{:});
                    dynProps = obj.webcamImpl.getDynamicProperties();
                    dynPropKeys = dynProps.keys;
                    dynPropValues = dynProps.values;
                    for i=1:dynProps.size()
                        prop = addprop(obj,dynPropKeys{i});
                        obj.(dynPropKeys{i}) = dynPropValues{i};
                        prop.SetAccess = 'public';
                        prop.Dependent = true;
                        prop.AbortSet = true; % Is this ok?
                        prop.SetMethod = @(obj, value) obj.webcamImpl.setDynamicProperty(prop.Name, value);
                        prop.GetMethod = @(obj) obj.webcamImpl.getDynamicProperty(prop.Name);
                    end
                else
                    % This is running in MATLAB Online, create a webcamOnline
                    % object.
                    obj.webcamImpl = matlab.webcam.internal.webcamOnline(varargin{:});
                end
            catch e
                % If there were errors creating a webcamOnline or
                % webcamDesktop object, error out.
                throw(e);
            end
        end
    end
    
    % GET/SET methods
    methods
        function value = get.Name(obj)
            value = obj.webcamImpl.Name;
        end
        
        function value = get.Resolution(obj)
            value = obj.webcamImpl.Resolution;
        end
        
        function value = get.AvailableResolutions(obj)
            value = obj.webcamImpl.AvailableResolutions;
        end
        
        function set.Resolution(obj,value)
            obj.webcamImpl.setResolution(value);
        end
        
        % Generic set method
        function varargout = set(obj, varargin)
            try
                if (nargin==1) || (nargin==2 && ~isstruct(varargin{1}))
                    out = obj.webcamImpl.set(varargin{:});
                    varargout = {out};
                else
                    set(obj.webcamImpl,varargin{:});
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function value = get(obj, varargin)
            try
                value = obj.webcamImpl.get(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    % Public Methods
    methods
        % Preview can return an hImage in desktop, but currently does not
        % return anything in MATLAB Online
        function varargout = preview(obj,varargin)
            try
                if matlab.webcam.internal.Utility.isMATLABOnline
                    if (nargout ~= 0)
                        throwAsCaller(MException('MATLAB:webcam:TooManyOutputs', 'Too many output arguments.'));
                    end
                    % If the AWS instance is killed/dies, then when the session comes back, check to see if the webcamImpl exists.
                    if isempty(obj.webcamImpl)
                        error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
                    end
                    obj.webcamImpl.preview();
                else
                    nargoutchk(0,1);
                    % Return an output only if requested.
                    if (nargout > 0)
                        varargout = obj.webcamImpl.preview(varargin{:});
                        varargout = {varargout};
                    else
                        obj.webcamImpl.preview(varargin{:})
                    end        
                end
            catch e
                if (strcmp(e.identifier,'MATLAB:unassignedOutputs') && (matlab.webcam.internal.Utility.isMATLABOnline))
                    % MATLAB Online does not return an output argument for
                    % preview, so dont error out.
                else
                    throwAsCaller(e);
                end
            end
        end
        
        function [image, timestamp] = snapshot(obj)
            try
                % If the AWS instance is killed/dies, then when the session comes back, check to see if the webcamImpl exists.
                if isempty(obj.webcamImpl)
                    error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
                end
                [image, timestamp]  = obj.webcamImpl.snapshot;
            catch e
                throwAsCaller(e);
            end
        end
        
        function closePreview(obj)
            try
                obj.webcamImpl.closePreview;
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    % Public Hidden Methods that will be disabled
    methods(Access = public, Hidden)
        
        function c = horzcat(varargin)
            %HORZCAT Horizontal concatenation of Webcam objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            end
        end
        function c = vertcat(varargin)
            %VERTCAT Vertical concatenation of Webcam objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            end
        end
        function c = cat(varargin)
            %CAT Concatenation of Webcam objects.
            if (nargin > 2)
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            else
                c = varargin{2};
            end
        end
        
        % Hidden methods from the hgsetget super class.
        function res = eq(obj, varargin)
            res = eq@hgsetget(obj, varargin{:});
        end
        function res = ge(obj, varargin)
            res = ge@hgsetget(obj, varargin{:});
        end
        function res = gt(obj, varargin)
            res = gt@hgsetget(obj, varargin{:});
        end
        function res = le(obj, varargin)
            res = le@hgsetget(obj, varargin{:});
        end
        function res = lt(obj, varargin)
            res = lt@hgsetget(obj, varargin{:});
        end
        function res = ne(obj, varargin)
            res = ne@hgsetget(obj, varargin{:});
        end
        function res = findobj(obj, varargin)
            res = findobj@hgsetget(obj, varargin{:});
        end
        function res = findprop(obj, varargin)
            res = findprop@hgsetget(obj, varargin{:});
        end
        function res = addlistener(obj, varargin)
            res = addlistener@hgsetget(obj, varargin{:});
        end
        function res = notify(obj, varargin)
            res = notify@hgsetget(obj, varargin{:});
        end
        
        % Hidden methods from the dynamic proper superclass
        function res = addprop(obj, varargin)
            res = addprop@dynamicprops(obj, varargin{:});
        end
        
        
        function delete(obj)
            try
                if ~isempty(obj.webcamImpl)
                    obj.webcamImpl.delete();
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function out = saveobj(obj, varargin)
            try
                if matlab.webcam.internal.Utility.isMATLABOnline
                    out = obj.webcamImpl.saveOnlineObj;
                else
                    out = obj.webcamImpl.saveobj(varargin{:});
                end
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods(Static, Hidden)
        % load and save methods
        function obj = loadobj(inStruct)
            try
                if ~matlab.webcam.internal.Utility.isMATLABOnline
                    obj = matlab.webcam.internal.webcamDesktop.loadobj(inStruct);
                else
                    obj = matlab.webcam.internal.webcamOnline.loadOnlineObj(inStruct);
                end
            catch e
                throwAsCaller(e);
            end
        end
    end
end
