Select 
	 tl.id TemplateLineId
	 ,t.id TemplateId
	,t.name TemplateName From template_line as tl

INNER JOIN template as t on tl.tid = t.id



