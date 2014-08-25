<h2>Description</h2>
<p>This plugin allows wheels to correctly read table metadata accross Oracle remote database link</p>
<p>The dblink should be used via a synonym and NOT directly in the model</p>

<h2>Usage/Examples</h2>
<p>In synonym</p>
<p>
<pre>
CREATE SYNONYM users FOR users@mydblink;
</pre>
In your /controllers/Users.cfc: </p>
<p>
<pre>
&lt;cfcomponent extends="Controller">
    &lt;cffunction name="new">
        &lt;cfset user = model("user").new()>
    &lt;/cffunction>
&lt;/cfcomponent>
</pre>
