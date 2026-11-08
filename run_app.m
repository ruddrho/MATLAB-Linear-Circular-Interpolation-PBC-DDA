function app = run_app(view)
%RUN_APP Launch CNC Interpolation Studio PRO.
%   run_app            Open the Classic View by default.
%   run_app('classic')  Explicitly launch the Classic View.
%   run_app('pro')      Open the tabbed Professional Dashboard directly.
%
    if nargin < 1 || isempty(view)
        view = 'classic';
    end
    if ~(ischar(view) || (isstring(view) && isscalar(view)))
        error('CNCStudio:InvalidView', ...
            'View must be ''classic'' or ''pro''.');
    end
    switch lower(strtrim(char(view)))
        case 'classic'
            app = CNCInterpolationApp();
        case 'pro'
            app = CNCProfessionalDashboard();
        otherwise
            error('CNCStudio:InvalidView', ...
                'Unknown view: %s. Choose ''classic'' or ''pro''.',char(view));
    end
    if nargout == 0
        clear app
    end
end
