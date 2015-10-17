import filter_jeff as fj
import jeffs_functions as jf
import shutil
import os
import glob
import numpy as np
import displacement_jeff as dj

def main():
    #what size images are we working with??
    width = 256
    height = width
    frame_ref=400
    f_rate=30.
    f_low=[.1,.3]
    f_high=[1.,3.]
    #define the base dirs for the data and analysis
    #note that these should become network locations
    base_dir_data='/Users/jledue/Documents/PYTHON/AHF Data/'
    base_dir_analysis='/Users/jledue/Documents/PYTHON/AHF Analysis/'
    to_analyze=jf.check_dirs(base_dir_data,base_dir_analysis)
    print(to_analyze)
    
    #start a loop on the folders to analyze and do some things.
    #we need to make a local copy for speed of loading and saving
    base_dir_tmp='/Users/jledue/Documents/PYTHON/tmp/'
    for f in to_analyze:
        #Check if the tmp dir exists or not, copy over the dirs in the date folder
        if os.path.isdir(base_dir_tmp):
            print('tmp found, deleting')
            shutil.rmtree(base_dir_tmp)
            shutil.copytree(base_dir_data+f,base_dir_tmp)
        else:
            shutil.copytree(base_dir_data+f,base_dir_tmp)
            print('tmp not found, just copying')
            
        #figure out which cages are present
        #print('These are the cages '+str(jf.check_cages(base_dir_tmp))+' in'+f)
        the_cages=jf.check_cages(base_dir_tmp)
        
        #continue doing stuff
        #step one is to read in all the raw data and save all the green videos
        if len(the_cages)>0:
            for c in the_cages:
                #setup the dir for reading the raw data
                data_dir=base_dir_tmp+str(c)+'/Videos/'
                #which mice are in the cage?
                the_mice=jf.check_mice(data_dir)
                #print(data_dir)
                os.chdir(data_dir)
                raw_list=glob.glob('*.raw')
                green_dir=base_dir_tmp+c+'/Green/'
                os.makedirs(green_dir)
                for rf in raw_list:
                    frames=fj.get_frames(data_dir+rf,width,height)
                    out_green_fn=rf[:-4]+'.g'
                    fj.save_to_file(green_dir,out_green_fn,frames,np.uint8)
                print('waiting...')
                #copy the resulting folder to the analysis location
                green_dir_to_copy=base_dir_analysis+f+'/'+c
                #print(green_dir_to_copy)
                if os.path.isdir(green_dir_to_copy+'/Green/'):
                    shutil.rmtree(green_dir_to_copy+'/Green/')
                    shutil.copytree(green_dir,green_dir_to_copy+'/Green/')
                else:
                    shutil.copytree(green_dir,green_dir_to_copy+'/Green/')

                #Do alignments!!
                print "Doing alignments..."
                aligned_dir=base_dir_tmp+c+'/Aligned/'
                os.makedirs(aligned_dir)
                for m in the_mice:
                    lof, lofilenames=dj.get_file_list(green_dir, m)
                    print(lof)
                    lp=dj.get_distance_var(lof,width,height,frame_ref)
                    for i in range(len(lp)):
                        print('Working on this file: ')+str(lof[i])
                        #tmp_lof=[]
                        #tmp_lof.append(lof[i])
                        #print('creating 1 element list')
                        #print(type(tmp_lof))
                        frames=dj.get_green_frames(str(lof[i]),width,height)
                        frames=dj.shift_frames(frames,lp[i])
                        #save it!
                        out_aligned_fn=str(lofilenames[i])
                        out_aligned_fn=out_aligned_fn[:-4]+'_aligned.g'
                        fj.save_to_file(aligned_dir,out_aligned_fn,frames,np.uint8)
                #copy the resulting folder to the analysis location
                aligned_dir_to_copy=base_dir_analysis+f+'/'+c
                if os.path.isdir(aligned_dir_to_copy+'/Aligned/'):
                    shutil.rmtree(aligned_dir_to_copy+'/Aligned/')
                    shutil.copytree(aligned_dir,aligned_dir_to_copy+'/Aligned/')
                else:
                    shutil.copytree(aligned_dir,aligned_dir_to_copy+'/Aligned/')
    
                #Do temporal filters, apply and calculate dff
                #each filter band
                for i in range(len(f_low)):
                    #set up a folder for this band
                    band_dir=base_dir_tmp+c+'/DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/'
                    #and for GSR version
                    gsrband_dir=base_dir_tmp+c+'/GSR_DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/'
                    os.makedirs(band_dir)
                    os.makedirs(gsrband_dir)
                    #go to the aligned tmp dir
                    os.chdir(aligned_dir)
                    aligned_list=glob.glob('*.g')
                    for af in aligned_list:
                        frames=dj.get_green_frames(aligned_dir+af,width,height)
                        avg_frames=fj.calculate_avg(frames)
                        frames=fj.cheby_filter(frames, f_low[i], f_high[i], f_rate)
                        frames+=avg_frames
                        frames=fj.calculate_df_f0(frames)
                        #save this
                        out_dff_fn=af[:-4]+'_DFF_'+str(f_low[i])+'-'+str(f_high[i])+'Hz.raw'
                        fj.save_to_file(band_dir,out_dff_fn,frames,np.float32)
                        #do gsr
                        frames=fj.gsr(frames,width,height)
                        #save this
                        out_gsr_fn=af[:-4]+'_GSR_DFF_'+str(f_low[i])+'-'+str(f_high[i])+'Hz.raw' 
                        fj.save_to_file(gsrband_dir,out_gsr_fn,frames,np.float32)
                    #copy the resulting folder to the analysis location
                    dff_dir_to_copy=base_dir_analysis+f+'/'+c
                    if os.path.isdir(dff_dir_to_copy+'/DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/'):
                        shutil.rmtree(dff_dir_to_copy+'/DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/')
                        shutil.copytree(band_dir,dff_dir_to_copy+'/DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/')
                    else:
                        shutil.copytree(band_dir,dff_dir_to_copy+'/DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/')
                    gsr_dir_to_copy=base_dir_analysis+f+'/'+c
                    if os.path.isdir(gsr_dir_to_copy+'/GSR_DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/'):
                        shutil.rmtree(gsr_dir_to_copy+'/GSR_DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/')
                        shutil.copytree(gsrband_dir,gsr_dir_to_copy+'/GSR_DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/')
                    else:
                        shutil.copytree(gsrband_dir,gsr_dir_to_copy+'/GSR_DFF_Freq_Band_'+str(f_low[i])+'-'+str(f_high[i])+'Hz/')
                        
                    
                
        else:
            print('No cages present, sry :(')
            
        
        #at end of loop make sure to clean up tmp folder
        shutil.rmtree(base_dir_tmp)
            
main()

