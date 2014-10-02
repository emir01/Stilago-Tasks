SELECT 
  tl.id  TemplateLineId
 ,(SELECT t.id from template as t where t.parent_id = tl.tid)
FROM template_line as tl


SELECT id, tid, parent_id from template_line


SELECT t.id, t.parent_id FROM template as t where t.parent_id = '11'
	