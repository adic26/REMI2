SELECT d.type, f.f_id, u.ju_id, ol.drop_num, f.fm_id, f.failure_comment, image_exists(f.f_id) as imageExists, h.description, u.unit_number
    FROM drops d, job_units u, job_header h, orientation_list_data ol, failure f
    WHERE h.job_id=u.Job_id
    and u.ju_id = d.ju_id
    and h.description like 'QRA-14%'
    and f.drop_id = d.drop_id
    and ol.old_id = d.old_id
   -- and nvl(d.type, 'DROP') = 'DROP'
    AND SYSDATE BETWEEN f.create_date AND nvl( f.term_date, sysdate + 1 )
    ORDER BY u.ju_id, ol.drop_num desc;
    
    select ol.ol_id, ol.description,ol.type
    from orientation_lists ol
    where sysdate between cre_date and nvl(term_Date, sysdate + 1)
    order by ol_id asc;
    
    select ju.ju_id, o.drop_num, a.f_id, a.at_id, a.at_type, 'http://hwqaweb/relab_alpha/docs/' || a.path, ju.unit_number,h.description, a.CONTENT,
    f.image, f.failure_comment, f.drop_id, fm.description as failuredesc, d.ju_id as dropunitid, d.type
    from job_units ju, drops d, orientation_list_data o, attachments a, job_header h, failure f, failure_mode fm
    where a.drop_id = d.drop_id
    and d.old_id = o.old_id
    and d.ju_id = ju.ju_id
    and h.job_id=ju.Job_id
    and h.description like 'QRA-14%'
    and f.f_id=a.f_id
    and fm.fm_id=f.fm_id
    and sysdate between a.cre_date and nvl( a.term_date, sysdate + 1 )
    order by o.unit, o.drop_num;
