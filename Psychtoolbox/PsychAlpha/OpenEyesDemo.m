function OpenEyesDemo

AssertOpenGL;

KbName('UnifyKeyNames');
leftArrow = KbName('LeftArrow');
rightArrow = KbName('RightArrow');
upArrow = KbName('UpArrow');
downArrow = KbName('DownArrow');
rightGUI = KbName('rightGUI');
rightShiftKey = KbName('RightShift');
spaceKey = KbName('space');
oldPressSecs = 0;
count = 0;
ListenChar(2);

try
    
    screenid = max(Screen('Screens'));
    oldsync=Screen('Preference', 'SkipSyncTests', 2);
    win = Screen('OpenWindow', screenid, 0, [0 0 800 600]);
    ShowCursor('CrossHair', screenid);
    
    oeyes = PsychOpenEyes('OpenTracker', 1, win);
    oldgain = PsychCamSettings('Gain', oeyes)
    gain = PsychCamSettings('Gain', oeyes, 174)
    imgtype = 0;
    
    while 1
        % Show eye image:
        tex =Screen('GetCapturedImage', win, oeyes, 1);
        Screen('DrawTexture', win, tex, [], Screen('Rect', tex));

        % Flip at next retrace, but don't do anything to buffers, we'll
        % overwrite anyway:
        Screen('Flip', win, 0, 2);

        [clicks, mx, my] = GetClicks(win);
        Screen('DrawTexture', win, tex, [], Screen('Rect', tex));
        Screen('FrameOval', win, [255 255 0], CenterRectOnPoint([0 0 5 5], mx, my), 3, 3);
        Screen('Flip', win, 0, 2);
        mxs = mx;
        mys = my;

        [clicks, mx, my] = GetClicks(win);
        mxe = mx;
        mye = my;
        Screen('DrawTexture', win, tex, [], Screen('Rect', tex));
        eyeRect = [min(mxs, mxe), min(mys, mye), max(mxs, mxe), max(mys, mye)];
        Screen('FrameRect', win, [255 255 0], eyeRect);
        Screen('Flip', win, 0, 2);

        % Release old texture:
        Screen('Close', tex);
        clicks = GetClicks(win);
        if clicks > 1
            break;
        end
    end
    
    minDist = RectWidth(eyeRect) / 8
    maxDist = RectWidth(eyeRect) / 2 * 1.5
%     apprArea = RectWidth(eyeRect)/2 * RectHeight(eyeRect)/2 * pi;
    apprArea = max(RectWidth(eyeRect), RectWidth(eyeRect))/2;
    minArea = apprArea * 0.8
    maxArea = apprArea * 1.2

    PsychOpenEyes('SetDynamicConstraints', oeyes, minDist, maxDist, minArea, maxArea);
    
    while 1

        % Query mouse:
        [mx, my, mbutton] = GetMouse(win);

        if mbutton(3)
            break;
        end

        if mbutton(1)
            % Wait for next gaze position sample, set new pupil center pos.
            eyesample = PsychOpenEyes('GetGazePosition', oeyes, mx, my);
        else
            % Wait for next gaze position sample:
            eyesample = PsychOpenEyes('GetGazePosition', oeyes);
        end

        [keysDown, PressSecs, keyCode] = KbCheck;
        if keysDown && ((PressSecs - oldPressSecs)>0.1)
            dx = 0;
            dy = 0;

            if keyCode(leftArrow)
                dx = -1;
            end

            if keyCode(rightArrow)
                dx = +1;
            end

            if keyCode(downArrow)
                dy = -1;
            end

            if keyCode(upArrow)
                dy = +1;
            end

            % Query current settings:
            curpar = PsychOpenEyes('TrackerParameters', oeyes);
            exposure = PsychCamSettings('ExposureTime', oeyes);
            
            if keyCode(rightGUI)
                % Change rays or feature candidate parameters:
                curpar.rays = curpar.rays + dx;
                curpar.minCand = curpar.minCand + dy;
            else
                if keyCode(rightShiftKey)
                    % Change cornea search window size:
                    curpar.corneaWinSize = curpar.corneaWinSize + 10*dx;
                    if dy~=0
                        exposure = exposure + dy/10;
                        PsychCamSettings('ExposureTime', oeyes, exposure);
                    end
                else
                    % Change detection thresholds:
                    curpar.pupilEdgeThresh = curpar.pupilEdgeThresh + dx;
                    curpar.edgeThresh = curpar.edgeThresh + dy;
                end
            end

            if keyCode(spaceKey)
                switch imgtype
                    case 0,
                        imgtype = 2;
                    case 2,
                        imgtype = 3;
                    case 3,
                        imgtype = 4;
                    case 4,
                        imgtype = 0;
                end
            end

            if oldPressSecs == 0
                % First time invocation: Set a few defaults:
                curpar.eccentricity = 1.1;
                curpar.initialAngleSpread = 360; % This works with visible spectrum imaging.
                %            curpar.initialAngleSpread = 90;
                curpar.pupilEdgeThresh = 1;
            end
            
            % Commit (possibly changed) parameters to tracker:
            PsychOpenEyes('TrackerParameters', oeyes, curpar.pupilEdgeThresh, curpar.rays, curpar.minCand, curpar.corneaWinSize, curpar.edgeThresh, curpar.gaussWidth, curpar.eccentricity, curpar.initialAngleSpread);

            % Clear the framebuffers:
            Screen('Flip', win);

            % Draw text with new tracker settings:
            tstring = sprintf('Pupilthresh: %i , Edgethresh: %i , WinSize: %i , Rays: %i , Cand: %i, Exp: %f \nExcent.: %f , Spread: %f', curpar.pupilEdgeThresh, curpar.edgeThresh, ...
                curpar.corneaWinSize, curpar.rays, curpar.minCand, exposure, curpar.eccentricity, curpar.initialAngleSpread);
            fprintf('%s\n', tstring);
            DrawFormattedText(win, tstring, 0, 485, 255, 240);
            Screen('Flip', win);
            DrawFormattedText(win, tstring, 0, 485, 255, 240);
            Screen('Flip', win, 0, 2);

            % Done with keyboard handling...
            % Keyboard debouncer update:
            oldPressSecs = PressSecs;
        end

        % Fetch debug images: This must be after calling 'GetGazePosition',
        % otherwise you'll get stale images from previous cycle!
        tex = PsychOpenEyes('GetTrackerTexture', oeyes, imgtype);

        % Show eye image:
        Screen('DrawTexture', win, tex, [], Screen('Rect', tex));

        % Flip at next retrace, but don't do anything to buffers, we'll
        % overwrite anyway:
        Screen('Flip', win, 0, 2);

        % Release old texture:
        Screen('Close', tex);

        % Print out tracking results:
        %disp(eyesample);

        % Ready for next iteration...
        count = count + 1;
    end

    PsychOpenEyes('CloseTracker', oeyes);
    ShowCursor('Arrow', screenid);
    Screen('CloseAll');
    ListenChar(0);
    Screen('Preference', 'SkipSyncTests', oldsync);
    return;
catch
    ListenChar(0);
    PsychOpenEyes('CloseTracker', oeyes);
    ShowCursor('Arrow', screenid);
    Screen('CloseAll');
    Screen('Preference', 'SkipSyncTests', oldsync);
    psychrethrow(psychlasterror);
    return;
end