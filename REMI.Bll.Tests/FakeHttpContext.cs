using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Security.Principal;
using System.IO;
using System.Web.SessionState;
using System.Reflection;
using System.Configuration;
using System.Web.Security;

namespace REMI.Bll.Tests
{
    public class FakeHttpContext
    {
        public FakeHttpContext()
        {
            var httpRequest = new HttpRequest("", "http://localhost/", "");
            var httpResponce = new HttpResponse(new StringWriter());
            var httpContext = new HttpContext(httpRequest, httpResponce);
            var sessionContainer = new HttpSessionStateContainer("id", new SessionStateItemCollection(), new HttpStaticObjectsCollection(), 10,
                true, HttpCookieMode.AutoDetect, SessionStateMode.InProc, false);
            httpContext.Items["AspSession"] = typeof(HttpSessionState).GetConstructor(BindingFlags.NonPublic | BindingFlags.Instance, null, CallingConventions.Standard,
                new[] { typeof(HttpSessionStateContainer) }, null).Invoke(new object[] { sessionContainer });

            System.Security.Principal.IPrincipal user;
            var winId = new WindowsIdentity(ConfigurationManager.AppSettings["userName"].ToString());
            user = new WindowsPrincipal(winId);
            httpContext.User = user;
            HttpContext.Current = httpContext;
        }

        public HttpContext Current
        {
            get
            {
                return HttpContext.Current;
            }
        }
    }
}
