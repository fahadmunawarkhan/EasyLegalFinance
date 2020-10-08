/**
 * @File Name          : AccountNotesPrintableCtrl.cls
 * @Description        : 
 * @Author             : fahad.khan@toptal.com
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 10-01-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/5/2020   fahad.khan@toptal.com     Initial Version
**/
public class AccountNotesPrintableCtrl {
    public list<NoteWrapper> contentNotes{get;set;}
    public String ObjName {get;set;}
    public String ObjId {get;set;}
    public AccountNotesPrintableCtrl()
    {
        ObjId = System.currentPageReference().getParameters().get('Id');
        Set<Id> noteIds = new Set<Id>();
        for(ContentDocumentLink n : [select ContentDocumentId from ContentDocumentLink where LinkedEntityId =: ObjId])
        {
            noteIds.add(n.ContentDocumentId);
        }
        
        contentNotes = new List<NoteWrapper>();
        for(ContentNote n : [Select id, Title, content, createddate, createdbyId, createdBy.Name, TextPreview , Owner.Name 
                             from ContentNote
                             where id in:noteIds order by createdDate desc, Title desc])
        {   
            NoteWrapper w = new NoteWrapper();
            w.content = n.content.toString().unescapeHtml4().unescapeHtml3().unescapeJava();
            w.note = n;
            
            w.noteDateTime = n.CreatedDate;          
            if(n.Title != null && n.Title != 'N/A'){
                try{
                    Date dt = Date.valueOf(n.Title);//In case if title is other then datetime it will through exception
                    w.noteDateTime = DateTime.newInstance(dt.year(), dt.month(), dt.day());
                }Catch(exception e){
                    w.noteDateTime = n.CreatedDate;
                }
            }
            contentNotes.add(w);            
        }
        contentNotes.sort();
        if(!String.isEmpty(ObjId))
            ObjName = CustomNotesComponentCtrl.getObjectName(ObjId);
    }
    public class NoteWrapper implements Comparable
    {
        public ContentNote note{get;set;}
        public String content{get;set;}
        public DateTime noteDateTime{get;set;}

        public Integer compareTo(Object compareTo){
            NoteWrapper noteWrapper = (NoteWrapper) compareTo;
            if (noteDateTime == noteWrapper.noteDateTime) return 0;
            if (noteDateTime < noteWrapper.noteDateTime) return 1;
            return -1;        
        }
    }
}