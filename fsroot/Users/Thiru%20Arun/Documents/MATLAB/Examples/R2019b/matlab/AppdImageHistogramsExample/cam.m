  %% Setup Image Acquisition
                    hCamera = webcam;
                    hShow= imshow(zeros(1280,720,3,'uint8'),'Parent',app.UIAxes)
                    title('Camera', 'Parent',app.UIAxes);

            %% Refernce Images
                    imgRef = snapshot(hCamera);
                    Drowsy_Count=0;


            %% Quantize images and outputing to the screen
                    frames = 100;
                    for i = 1: frames
                         %Acquire an image from webcam
                             imgVid = snapshot(hCamera);
    
                         %Call the live fegmentation function
                              [object_detected,x] = Segment_fn(imgRef,imgVid);
    
                         %Update the imshow handle with new image
                                set(hShow, 'CData', object_detected);
                                drawnow;
                                    if x==-1
                                        Drowsy_Count=Drowsy_Count-1;
                                    else
                                        Drowsy_Count=Drowsy_Count+1;
                                    end     
                               
                    end
%% camera cover
     hShow= imshow(0,'Parent',app.UIAxes)
%% If the person was drowsy or not
if Drowsy_Count>=0
    disp('Not Drowsy');
    app.EditField.Value='Not Drowsy';
else
    disp('Drowsy');
    app.EditField.Value='Drowsy';
end