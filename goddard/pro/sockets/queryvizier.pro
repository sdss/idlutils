function Queryvizier, catalog, target, dis, VERBOSE=verbose, CANADA = canada
;+
; NAME: 
;   QUERYVIZIER
;
; PURPOSE: 
;   Query any catalog in the Vizier database by position
; 
; EXPLANATION:
;   Uses the IDL SOCKET command to provide a positional query of any catalog 
;   in the the Vizier (http://vizier.u-strasbg.fr/) database over the Web.    
;   Requires IDL V5.4 or later.
; 
;    
; CALLING SEQUENCE: 
;     info = QueryVizier(catalog, targetname_or_coords, [ dis )
;
; INPUTS: 
;      CATALOG - Scalar string giving the name of the VIZIER catalog to be
;            searched.    The complete list of catalog names is available at
;            http://vizier.u-strasbg.fr/vizier/cats/U.htx . 
;
;            Popular VIZIER catalogs include  
;            '2MASS-PSC' - 2MASS point source catalog (2003)
;            'GSC2.2' - Version 2.2 of the HST Guide Star Catalog (2003)
;            'USNO-B1' - Verson B1 of the US Naval Observatory catalog (2003)
;            'NVSS'  - NRAO VLA Sky Survey (1998)
;            'B/DENIS/DENIS' - 2nd Deep Near Infrared Survey of southern Sky
;            'I/259/TYC2' - Tycho-2 main catalog (2000)
;
;          Note that some names will prompt a search of multiple catalogs
;          and QUERYVIZIER will only return the result of the first search.
;          Thus, (as in the case of the Tycho catalog above), it may be 
;          important to use the specific VIZIER name.
;                             
;      TARGETNAME_OR_COORDS - Either a scalar string giving a target name, 
;          (with J2000 coordinates determined by SIMBAD), or a 2-element
;          numeric vector giving the J2000 right ascension in *degrees* and 
;          the target declination in degrees.
;
; OPTIONAL INPUT:
;    dis - scalar or 2-element vector.   If one value is supplied then this
;          is the search radius in arcminutes.     If two values are supplied
;          then this is the width (i.e., in longitude direction) and height of the
;          of the search box.   Default is a radius search with radius of
;          5 arcminutes
;
; OUTPUTS: 
;   info - IDL structure containing information on the catalog stars within the 
;          specified distance of the specified center.   The structure tags
;          are identical with the VIZIER catalog column names, with the 
;          exception of an occasional underscore addition, if necessary to 
;          convert the column name to a valid structure tag.    The VIZIER Web 
;          page should consulted for the column names and their meaning for 
;          each particular catalog..
;           
;          If the tagname is numeric and the catalog field is blank then either
;          NaN  (if floating) or -1 (if integer) is placed in the tag.
;
;          If no sources are found within the specified radius, or an
;          error occurs in the query then -1 is returned. 
; OPTIONAL KEYWORDS:
;          /CANADA - By default, the query is sent to the main VIZIER site in
;            Strasbourg, France.   If /CANADA is set then the VIZIER site
;            at the Canadian Astronomical Data Center (CADC) is used instead.
;            Note that not all Vizier sites have the option to return
;            tab-separated values (TSV) which is required by this program.
; EXAMPLES: 
;          (1) Plot a histogram of the J magnitudes of all 2MASS point sources 
;          stars within 10 arcminutes of the center of the globular cluster M13 
;
;          IDL>  info = queryvizier('2MASS-PSC','m13',10)
;          IDL> plothist,info.jmag,xran=[10,20]
;
;          (2)  Find the brightest R magnitude GSC2.2 source within 3' of the 
;               J2000 position ra = 10:12:34, dec = -23:34:35
;          
;          IDL> str = queryvizier('GSC2.2',[ten(10,12,34)*15,ten(-23,34,35)],3)
;          IDL> print,min(str.rmag,/NAN)
; PROCEDURES USED:
;          GETTOK(),IDL_VALIDNAME()(if prior to V6.0), RADEC, REMCHAR, REPSTR(),
;          WEBGET()
; TO DO:
;       (1) Allow specification of output sorting
;       (2) Allow non-positional queries.
; MODIFICATION HISTORY: 
;         Written by W. Landsman  SSAI  October 2003
;-
  if N_params() LT 3 then begin
       print,'Syntax - info = QueryVizier(catalog, targetname_or_coord, dis,'
       print,'                       '
       print,'  Coordinates (if supplied) should be J2000 RA (degrees) and Dec'
       print,'  dis -- search radius or box in arcminutes'
       if N_elements(info) GT 0 then return,info else return, -1
  endif

if keyword_set(canada) then root = "http://vizier.hia.nrc.ca" $
                       else  root = "http://vizier.u-strasbg.fr" 
 
  if N_elements(catalog) EQ 0 then $
            message,'ERROR - A catalog name must be supplied as a keyword'
  targname = 0b
 if N_elements(dis) EQ 0 then dis = 5
 if N_elements(dis) EQ 2 then $
    search = "&-c.bm=" + strtrim(dis[0],2) + '/' + strtrim(dis[1],2) else $
    search = "&-c.rm=" + strtrim(dis,2) 
    if N_elements(target) EQ 2 then begin
      ra = float(target[0])
      dec = float(target[1])
      RADEC,ra,dec,hr,mn,sc,deg,dmn,dsc,hours=keyword_set(hours)
   endif else begin 
       object = repstr(target,'+','%2B')
        object = repstr(strcompress(object),' ','+')
       targname = 1b 
  endelse
 source = catalog
 ;;
 if targname then $
  QueryURL = $
   root + "/cgi-bin/asu-tsv/?-source=" + source + $
     "&-c=" + object + search + '&-out.max=unlimited' else $
  queryURL = $
   root + "/cgi-bin/asu-tsv/?-source=" + source + $
       "&-c.ra=" + strtrim(ra,2) + '&-c.dec=' + strtrim(dec,2) + $
       search + '&-out.max=unlimited'
   ;;  
 if keyword_set(verbose) then message,queryurl,/inf
  Result = webget(QueryURL)
;

  t = strtrim(result.text,2)
  keyword = strmid(t,0,7)

  lcol = where(keyword EQ "#Column", Nfound)
  if Nfound EQ 0 then begin
       if max(strpos(strlowcase(t),'errors')) GE 0 then begin 
            message,'ERROR - Unsuccessful VIZIER query',/CON 
            print,t
       endif else message,'No sources found within specified radius',/INF
       return,-1
  endif
; Check to see if more than one catalog has been searched
  if N_elements(lcol) GT 1 then begin
      diff  = lcol[1:*] - lcol
      g = where(diff GT 1, Ng)
      if Ng GT 0 then lcol = lcol[0:g[0]]
  endif

  if keyword_set(verbose) then begin
    titcol = where(keyword EQ '#Title:', Ntit)
    if Ntit GT 0 then message,strtrim(strmid(t[titcol[0]],8,70),2),/inf
  endif

  trow = t[lcol]
  dum = gettok(trow,' ')
  colname = gettok(trow,' ')
  fmt = gettok(trow,' ')
  remchar,fmt,'('
  remchar,fmt,')'
  remchar,colname,')'
  val = fix(strmid(fmt,1,4))
  for i=0,N_elements(colname)-1 do $
         colname[i] = IDL_VALIDNAME(colname[i],/convert_all)
  source = IDL_VALIDNAME(source, /convert_all)

 ex_string = 'Name="' + source + '",["' +  strjoin(colname,'","') + '"]'
 ntag = N_elements(colname)
 for i=0,Ntag-1 do begin
 case strmid(fmt[i],0,1) of 
  'A': ex_string = ex_string  + ",''"
  'I': if val[i] LE 4 then ex_string = ex_string + ',0' else $
                           ex_string = ex_string + ',0L'
  'F': if val[i] LE 7 then ex_string = ex_string + ',0.' else $ 
                           ex_string = ex_string + ',0.0d'
   else: message,'ERROR - unrecognized format'
  endcase
 endfor

  status = execute( 'info = Create_struct(' +  ex_string + ')' )

  i0 = max(lcol) + 5  
  iend = where( t[i0:*] EQ '', Nend)
  if Nend EQ  0  then iend = N_elements(t) else iend = iend[0] + i0
  nstar = iend - i0 
  info = replicate(info,nstar)

; Find positions of tab characters 
  t = t[i0:iend-1]
  slen = max(strlen(t),c)  
  tt = t[c]
  spos = [strsplit(tt,string(9b)),slen]
  val = spos[1:*] - spos - 1

  for j=0,N_elements(spos)-2 do begin
      x = strtrim(strmid(t,spos[j],val[j] ),2)
       dtype = size(info[0].(j),/type)
      if dtype NE 7 then begin
      bad = where(strlen(x) EQ 0, Nbad)
     if (Nbad GT 0) then $
           if (dtype EQ 4) or (dtype EQ 5) then x[bad] = 'NaN' $
                                           else x[bad] = -1
      endif
      info.(j) = x 
   endfor


 return,info
END 
  
