-- COMP9311 Assignment 2
-- Written by TianYi Hou

-- Q1: get details of the current Heads of Schools


create or replace view Q1(name, school, starting)
as
select people.name ,OrgUnits.longname,Affiliation.starting from people ,OrgUnits,Affiliation,StaffRoles
where 
people.id=Affiliation.staff
And Affiliation.orgunit=orgunits.id
And OrgUnits.utype=2
And Affiliation.role=staffroles.id
And Affiliation.isPrimary='t'
And Affiliation.ending is NULL
And StaffRoles.description='Head of School'
;

-- Q2: longest-serving and most-recent current Heads of Schools

create or replace view Q2(status, name, school, starting)
as
select (case when q1.starting =(select max(starting) from q1) 
		then 'Most recent'
	    when  q1.starting =(select min(starting) from q1)
	    then 'Longest serving'
	    End) status,q1.* from q1
where 
q1.starting =(select max(starting) from q1) or  q1.starting =(select min(starting) from q1)
;
create or replace view avgMarks(courseID,avgMark)
as
select courseenrolments.course ,avg(courseenrolments.mark) from courseenrolments 
group by courseenrolments.course
Having count(1)>20 
;
create or replace view Maxavgmark(course,mark)
as
select avgmarks.courseid,avgmarks.avgmark from avgmarks
where avgmarks.avgmark=(select max(avgmarks.avgmark) from avgmarks)
;

-- Q3: highest average mark 

create or replace view Q3(code, year, sess, name)
as
select s.code, te.year, te.sess, pe.name 
from avgmarks av,subjects s,courses co,terms te,people pe,staff st,coursestaff cs,courseroles cr
where
co.id=av.courseid
and av.avgmark=(select max(avgmarks.avgmark) from avgmarks)
and co.subject=s.id
and co.term=te.id
and cs.course=co.id
and cs.staff=st.id
and cs.role=cr.id
and cr.name='Convenor'
and st.id=pe.id
;


-- Q4: percentage of international students, S1 and S2, 2005..2011

create or replace view Q4(term, percent)
as
select lower(substr(terms.year||terms.sess,3,4)) ,
((sum(case when students.stype='intl' then 1 else 0 end)+0.0)/count(1))::numeric(4,2) 
from programenrolments pr ,terms,students
where (terms.sess in('S1','S2')) and pr.term=terms.id and students.id=pr.student
and terms.year>=2005
group by lower(substr(terms.year||terms.sess,3,4)) 
;




-- Q5: total FTE students per term from 2001 S1 to 2010 S2

create or replace view Q5(term, nstudes, fte)
as
select lower(substr(te.year||te.sess,3,4)),
count(distinct ce.student),
((sum(s.uoc)+0.0)/24)::numeric(6,1)
from courseEnrolments ce ,terms te,subjects s,courses co
where 
co.id=ce.course 
and co.subject=s.id 
and co.term=te.id
and te.year>=2000
and te.year<=2010
and te.sess in('S1','S2')
group by lower(substr(te.year||te.sess,3,4))
;


-- Q6: subjects with > 30 course offerings and no staff recorded

create or replace view Q6(subject, nOfferings)
as
select sbj,noffice from(select subjects.code||' '||subjects.name as sbj,count(courses.id) as noffice
from subjects,courses
where 
courses.subject=subjects.id
and subjects.id not in
(select subjects.id from subjects,courses,coursestaff
where
courses.subject=subjects.id
and coursestaff.course=courses.id
)
group by subjects.code||' '||subjects.name) as se
where se.noffice>30
;


-- Q7:  which rooms have a given facility


create or replace function
	Q7(text) returns setof FacilityRecord
as $$
    select rooms.longname ,facilities.description 
	from rooms,facilities,roomfacilities
	where 
	rooms.id=roomfacilities.room 
	and facilities.id=roomfacilities.facility
	and lower(facilities.description) like lower('%'||$1||'%');
	
$$ language sql;



-- Q8: semester containing a particular day

create or replace function Q8(_day date) returns text 
as $$
declare
yearsess text;
maxdate  date;
mindate  date;

begin
select min(terms.starting),max(terms.ending) into mindate,maxdate from terms;
if $1<=maxdate and $1>= mindate then
       select lower(tt) into yearsess 
	   from(
		   select substr(y||se,3,4) tt,
		   case when age(s,preTermEnding)>=interval'7 day' and preTermEnding is not null then s-interval'7 day' else preTermEnding+interval'1 day' end st,
		   case when age(posTermStarting,e)>=interval'7 day' and posTermStarting is not null then posTermStarting-interval'8 day'else e end ed
		   from(
	       select terms.year y,
            terms.sess se,
		    terms.starting s,
		    terms.ending e,
            lag(terms.starting,1)over(order by terms.starting) preTermStarting,
            lag(terms.ending,1)over(order by terms.starting) preTermEnding,
            lag(terms.starting,-1)over(order by terms.starting) posTermStarting,
            lag(terms.ending,-1)over(order by terms.starting) posTermEnding
            from terms ) prpo)resu
			where $1 between st and ed ;
else 
yearsess :=NULL;
end if;
return yearsess;
end;
$$ language plpgsql
;



-- Q9: transcript with variations


-- COMP9311 Assignment 2
-- Written by TianYi Hou

-- Q1: get details of the current Heads of Schools


create or replace view Q1(name, school, starting)
as
select people.name ,OrgUnits.longname,Affiliation.starting from people ,OrgUnits,Affiliation,StaffRoles
where 
people.id=Affiliation.staff
And Affiliation.orgunit=orgunits.id
And OrgUnits.utype=2
And Affiliation.role=staffroles.id
And Affiliation.isPrimary='t'
And Affiliation.ending is NULL
And StaffRoles.description='Head of School'
;

-- Q2: longest-serving and most-recent current Heads of Schools

create or replace view Q2(status, name, school, starting)
as
select (case when q1.starting =(select max(starting) from q1) 
		then 'Most recent'
	    when  q1.starting =(select min(starting) from q1)
	    then 'Longest serving'
	    End) status,q1.* from q1
where 
q1.starting =(select max(starting) from q1) or  q1.starting =(select min(starting) from q1)
;
create or replace view avgMarks(courseID,avgMark)
as
select courseenrolments.course ,avg(courseenrolments.mark) from courseenrolments 
group by courseenrolments.course
Having count(1)>20 
;
create or replace view Maxavgmark(course,mark)
as
select avgmarks.courseid,avgmarks.avgmark from avgmarks
where avgmarks.avgmark=(select max(avgmarks.avgmark) from avgmarks)
;

-- Q3: highest average mark 

create or replace view Q3(code, year, sess, name)
as
select s.code, te.year, te.sess, pe.name 
from avgmarks av,subjects s,courses co,terms te,people pe,staff st,coursestaff cs,courseroles cr
where
co.id=av.courseid
and av.avgmark=(select max(avgmarks.avgmark) from avgmarks)
and co.subject=s.id
and co.term=te.id
and cs.course=co.id
and cs.staff=st.id
and cs.role=cr.id
and cr.name='Convenor'
and st.id=pe.id
;


-- Q4: percentage of international students, S1 and S2, 2005..2011

create or replace view Q4(term, percent)
as
select lower(substr(terms.year||terms.sess,3,4)) ,
((sum(case when students.stype='intl' then 1 else 0 end)+0.0)/count(1))::numeric(4,2) 
from programenrolments pr ,terms,students
where (terms.sess in('S1','S2')) and pr.term=terms.id and students.id=pr.student
and terms.year>=2005
group by lower(substr(terms.year||terms.sess,3,4)) 
;




-- Q5: total FTE students per term from 2001 S1 to 2010 S2

create or replace view Q5(term, nstudes, fte)
as
select lower(substr(te.year||te.sess,3,4)),
count(distinct ce.student),
((sum(s.uoc)+0.0)/24)::numeric(6,1)
from courseEnrolments ce ,terms te,subjects s,courses co
where 
co.id=ce.course 
and co.subject=s.id 
and co.term=te.id
and te.year>=2000
and te.year<=2010
and te.sess in('S1','S2')
group by lower(substr(te.year||te.sess,3,4))
;


-- Q6: subjects with > 30 course offerings and no staff recorded

create or replace view Q6(subject, nOfferings)
as
select sbj,noffice from(select subjects.code||' '||subjects.name as sbj,count(courses.id) as noffice
from subjects,courses
where 
courses.subject=subjects.id
and subjects.id not in
(select subjects.id from subjects,courses,coursestaff
where
courses.subject=subjects.id
and coursestaff.course=courses.id
)
group by subjects.code||' '||subjects.name) as se
where se.noffice>30
;


-- Q7:  which rooms have a given facility


create or replace function
	Q7(text) returns setof FacilityRecord
as $$
    select rooms.longname ,facilities.description 
	from rooms,facilities,roomfacilities
	where 
	rooms.id=roomfacilities.room 
	and facilities.id=roomfacilities.facility
	and lower(facilities.description) like lower('%'||$1||'%');
	
$$ language sql;



-- Q8: semester containing a particular day

create or replace function Q8(_day date) returns text 
as $$
declare
yearsess text;
maxdate  date;
mindate  date;

begin
select min(terms.starting),max(terms.ending) into mindate,maxdate from terms;
if $1<=maxdate and $1>= mindate then
       select lower(tt) into yearsess 
	   from(
		   select substr(y||se,3,4) tt,
		   case when age(s,preTermEnding)>=interval'7 day' and preTermEnding is not null then s-interval'7 day' else preTermEnding+interval'1 day' end st,
		   case when age(posTermStarting,e)>=interval'7 day' and posTermStarting is not null then posTermStarting-interval'8 day'else e end ed
		   from(
	       select terms.year y,
            terms.sess se,
		    terms.starting s,
		    terms.ending e,
            lag(terms.starting,1)over(order by terms.starting) preTermStarting,
            lag(terms.ending,1)over(order by terms.starting) preTermEnding,
            lag(terms.starting,-1)over(order by terms.starting) posTermStarting,
            lag(terms.ending,-1)over(order by terms.starting) posTermEnding
            from terms ) prpo)resu
			where $1 between st and ed ;
else 
yearsess :=NULL;
end if;
return yearsess;
end;
$$ language plpgsql
;



-- Q9: transcript with variations


create or replace function
	q9(_sid integer) returns setof TranscriptRecord
as $$
declare
    declare
	rec TranscriptRecord;
	UOCtotal integer := 0;
	UOCpassed integer := 0;
	wsum integer := 0;
	wam integer := 0;
	x integer;
	aa text;
begin
	select s.id into x
	from   Students s join People p on (s.id = p.id)
	where  p.unswid = _sid;
	if (not found) then
		raise EXCEPTION 'Invalid student %',_sid;
	end if;
	for rec in
		select su.code, substr(t.year::text,3,2)||lower(t.sess),
			su.name, e.mark, e.grade, su.uoc
		from   CourseEnrolments e join Students s on (e.student = s.id)
			join People p on (s.id = p.id)
			join Courses c on (e.course = c.id)
			join Subjects su on (c.subject = su.id)
			join Terms t on (c.term = t.id)
		where  p.unswid = _sid
		order by t.starting,su.code
	loop
		if (rec.grade = 'SY') then
			UOCpassed := UOCpassed + rec.uoc;
		elsif (rec.mark is not null) then
			if (rec.grade in ('PT','PC','PS','CR','DN','HD')) then
				-- only counts towards creditted UOC
				-- if they passed the course
				UOCpassed := UOCpassed + rec.uoc;
			end if;
			-- we count fails towards the WAM calculation
			UOCtotal := UOCtotal + rec.uoc;
			-- weighted sum based on mark and uoc for course
			wsum := wsum + (rec.mark * rec.uoc);
		end if;
		return next rec;
	end loop;
	for rec in
	    select  su.code , null,
			v.vtype, v.student, case when v.intequiv is null then 'tt' else 'ff' end, su.uoc
		from   variations v 
		    join Students s on (v.student = s.id)
		    join People p on (s.id = p.id)
			join Subjects su on (v.subject = su.id)
		where  p.unswid = _sid
		order by su.code
	loop
		if rec.grade='tt' then
		    select 'study at '||e.institution into aa
  		    from  externalsubjects e 
			join variations v on (e.id=v.extequiv)
  		    where  v.student=rec.mark ;
		elsif rec.grade='ff'then
		    select 'studying '||s.code||' at UNSW' into aa
  		    from 
			variations v join subjects s on(v.intequiv=s.id)
  		    where  v.student=rec.mark ;
		end if;
		rec.grade :=null;
		rec.mark  :=null;
	    if rec.name='advstanding' then
		UOCpassed := UOCpassed + rec.uoc;
		rec.name :='Advanced standing, based on ...';
		return next rec;
		rec:=(null,null, aa,null,null,null);
		return next rec;
		elsif rec.name='substitution' then
		rec.name :='Substitution, based on ...';
		rec.uoc:=null;
		return next rec;
		rec:=(null,null, aa,null,null,null);
		return next rec;
		elsif rec.name='exemption' then 
		rec.uoc:=null;
		rec.name :='Exemption, based on ...';
		return next rec;
		rec:=(null,null, aa,null,null,null);
		return next rec;
		end if;
	end loop;
	if (UOCtotal = 0) then
		rec := (null,null,'No WAM available',null,null,null);
	else
		wam := wsum / UOCtotal;
		rec := (null,null,'Overall WAM',wam,null,UOCpassed);
	end if;
	-- append the last record containing the WAM
	return next rec;
	return;
end;
$$ language plpgsql
;