using FreshMvvm;
using System;

namespace LPains.LazyLoadedMasterDetailPage
{
    public class FreshViewModelMapper : IFreshPageModelMapper
    {
        public string GetPageTypeName(Type pageModelType)
        {
            return pageModelType.AssemblyQualifiedName
                .Replace("ViewModel", "View");
        }
    }
}
