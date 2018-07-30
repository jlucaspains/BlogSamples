using FreshMvvm;
using LPains.LazyLoadedMasterDetailPage.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace LPains.LazyLoadedMasterDetailPage.Helpers
{
    public class LazyLoadedPage
    {
        public string Title { get; set; }
        public string Icon { get; set; }
        public Page Page { get; set; }
        public Type ViewModelType { get; set; }
        public object Data { get; set; }
        public string Group { get; internal set; }
    }

    public class Grouping<K, T> : List<T>
    {
        public K Key { get; private set; }

        public Grouping(K key, List<T> items)
        {
            Key = key;
            foreach (var item in items)
                this.Add(item);
        }
    }

    public class MasterDetailNavigationContainer : Xamarin.Forms.MasterDetailPage, IFreshNavigationService
    {
        private MasterView _masterView;
        private ListView _listView;

        public ObservableCollection<LazyLoadedPage> Pages { get; } = new ObservableCollection<LazyLoadedPage>();

        public MasterDetailNavigationContainer() : this(Constants.DefaultNavigationServiceName)
        {

        }

        public MasterDetailNavigationContainer(string navigationServiceName)
        {
            NavigationServiceName = navigationServiceName;
        }

        public void Init(string menuTitle, string menuIcon = null)
        {
            CreateMenuPage(menuTitle, menuIcon);
            CreateDetailPage();
            RegisterNavigation();
        }

        protected virtual void RegisterNavigation()
        {
            FreshIOC.Container.Register<IFreshNavigationService>(this, NavigationServiceName);
        }

        public virtual void AddPage<T>(string title, string group, string icon = null, object data = null) where T : FreshBasePageModel
        {
            var pageToAdd = new LazyLoadedPage { ViewModelType = typeof(T), Data = data, Title = title, Icon = icon, Group = group };

            Pages.Add(pageToAdd);

            if (Pages.Count == 1)
                Detail = ResolvePage(pageToAdd);

            _listView.ItemsSource = Pages.GroupBy(item => item.Group).Select(item => new Grouping<string, LazyLoadedPage>(item.Key, item.ToList())).ToList();
        }

        public virtual void AddPage(string modelName, string title, string icon = null, object data = null)
        {
            var pageToAdd = new LazyLoadedPage { ViewModelType = Type.GetType(modelName), Data = data, Title = title, Icon = icon };

            Pages.Add(pageToAdd);

            if (Pages.Count == 1)
                Detail = ResolvePage(pageToAdd);
        }

        internal Page CreateContainerPageSafe(Page page)
        {
            if (page is NavigationPage || page is MasterDetailPage || page is TabbedPage)
                return page;

            return CreateContainerPage(page);
        }

        protected virtual Page CreateContainerPage(Page page)
        {
            return new NavigationPage(page);
        }

        protected virtual void CreateMenuPage(string menuPageTitle, string menuIcon = null)
        {
            _masterView = new MasterView();
            _listView = _masterView.FindByName<ListView>("ListView");

            var source = Pages.GroupBy(item => item.Group).Select(item => new Grouping<string, LazyLoadedPage>(item.Key, item.ToList())).ToList();

            _listView.ItemTapped += (sender, args) =>
            {
                var lazyLoadedPage = (LazyLoadedPage)args.Item;
                if (Pages.Contains(lazyLoadedPage))
                {
                    var page = lazyLoadedPage.Page;

                    if (page == null)
                        page = ResolvePage(lazyLoadedPage);

                    Detail = page;
                }

                IsPresented = false;
            };

            //menuPage.Content = _listView;

            var navPage = new NavigationPage(_masterView) { Title = menuPageTitle }; //adding an actual icon does't seem to work. The unicode here is a temporarily solution

            if (!string.IsNullOrEmpty(menuIcon))
            {
                navPage.Icon = menuIcon;
                Icon = menuIcon;
            }

            Master = navPage;
        }

        protected virtual void CreateDetailPage()
        {
            Detail = CreateContainerPage(new Page());
        }

        protected virtual Page ResolvePage(LazyLoadedPage lazyLoadedPage)
        {
            var innerPage = FreshPageModelResolver.ResolvePageModel(lazyLoadedPage.ViewModelType, lazyLoadedPage.Data);
            innerPage.GetModel().CurrentNavigationServiceName = NavigationServiceName;
            return CreateContainerPage(innerPage);
        }

        public Task PushPage(Page page, FreshBasePageModel model, bool modal = false, bool animate = true)
        {
            if (modal)
                return Navigation.PushModalAsync(CreateContainerPageSafe(page));
            return (Detail as NavigationPage).PushAsync(page, animate); //TODO: make this better
        }

        public Task PopPage(bool modal = false, bool animate = true)
        {
            if (modal)
                return Navigation.PopModalAsync(animate);
            return (Detail as NavigationPage).PopAsync(animate); //TODO: make this better            
        }

        public Task PopToRoot(bool animate = true)
        {
            return (Detail as NavigationPage).PopToRootAsync(animate);
        }

        public string NavigationServiceName { get; private set; }

        public void NotifyChildrenPageWasPopped()
        {
            if (Master is NavigationPage masterNavPage)
                masterNavPage.NotifyAllChildrenPopped();
            if (Master is IFreshNavigationService masterFreshNavPage)
                masterFreshNavPage.NotifyChildrenPageWasPopped();

            foreach (var page in this.Pages)
            {
                if (page.Page is NavigationPage navPage)
                    navPage.NotifyAllChildrenPopped();
                if (page.Page is IFreshNavigationService freshNavPage)
                    freshNavPage.NotifyChildrenPageWasPopped();
            }
            if (Pages != null && !Pages.Any(item => item.Page == Detail) && Detail is NavigationPage)
                ((NavigationPage)Detail).NotifyAllChildrenPopped();
            if (Pages != null && !Pages.Any(item => item.Page == Detail) && Detail is IFreshNavigationService)
                ((IFreshNavigationService)Detail).NotifyChildrenPageWasPopped();
        }

        public Task<FreshBasePageModel> SwitchSelectedRootPageModel<T>() where T : FreshBasePageModel
        {
            var lazyLoadedPage = Pages.FirstOrDefault(o => o.Page.GetModel().GetType().FullName == typeof(T).FullName);
            var page = lazyLoadedPage.Page;

            if (page == null)
                page = ResolvePage(lazyLoadedPage);

            _listView.SelectedItem = page;

            return Task.FromResult((Detail as NavigationPage).CurrentPage.GetModel());
        }
    }
}
