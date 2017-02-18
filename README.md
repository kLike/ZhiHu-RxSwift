# 坠入链式编程的幻乐里--用RxSwift仿写知乎日报

用过无数的三方库，却仍旧写不好代码。以前总会有人问：你用过最好的三方库是什么？那个时候总是会犹豫半天，到底是哪一个呢？好像都还可以耶，直到后来遇到[RxSwift](https://github.com/ReactiveX/RxSwift)，哇，简直打开了新世界的大门。现在我会毫不犹豫推荐它，虽然学习曲线有点陡峭，但是一旦你习惯上它，必深陷于其中无法自拔。

###初入RxSwift

在公司项目进入版本迭代的时期，总觉得应该学点什么，不然让拍在沙滩上怎么办？在学习swift3一段时间后，邂逅了响应式编程方式，看了一下相关文章，毫不犹豫跳入RxSwift的坑中，其中险些放弃，还好坚持下来了，现在也算入了个门。当然只看看理论知识点，光纸上谈兵是不行的，所以选择仿写知日报的方式来深化一下知识。

- 如果你不熟悉RxSwift相关的知识，可以先看看官方文档
[RxSwift](https://github.com/ReactiveX/RxSwift)
- 如果你不知道为什么要使用RxSwift，可以看看
[why use rx?](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Why.md)
- 如果你想入坑，推荐官方的demo，也可以在简书上搜索相关文章，推荐几篇文章：
[使用 RxSwift 进行响应式编程](https://realm.io/cn/news/altconf-scott-gardner-reactive-programming-with-rxswift/)，
[Getting Started With RxSwift and RxCocoa](http://southpeak.github.io/2017/01/16/Getting-Started-With-RxSwift-and-RxCocoa/)，
[RxSwift 入坑手册 Part1 - 示例实战](http://blog.callmewhy.com/2015/09/23/rxswift-getting-started-1/)

###项目实战

整个项目持续的大概两周，遇到不少问题，毕竟不管对于Swift还是RxSwift来说，我大概都只是个新手。

####网络请求 Moya + RxSwift

- [API](https://github.com/izzyleung/ZhihuDailyPurify/wiki/知乎日报-API-分析): 项目的开始当然是看看有没有API呀，这里要感谢这位通过非正常手段获取API的同学，为我们总结了完整的[知乎日报-API-分析](https://github.com/izzyleung/ZhihuDailyPurify/wiki/知乎日报-API-分析)，我也无私地奉献了star，略表感谢！
- [Alamofire](https://github.com/Alamofire/Alamofire): Swift版的AFNetworking。
- [Moya](https://github.com/Moya/Moya): 是 Artsy 团队的 Ash Furrow 主导开发的一个网络抽象层库。它在 Alamofire 基础上提供了一系列简单的抽象接口，让客户端代码不用去直接调用 Alamofire，也不用去关心 NSURLSession。同时提供了很多实用的功能，包括对RxSwift的良好扩展。
- [HandyJSON](https://github.com/alibaba/HandyJSON): 是一个用于Swift语言中的JSON序列化/反序列化库。与其他流行的Swift JSON库相比，HandyJSON的特点是，它支持纯swift类，使用也简单。它反序列化时(把JSON转换为Model)不要求Model从NSObject继承(因为它不是基于KVC机制)，也不要求你为Model定义一个Mapping函数。只要你定义好Model类，声明它服从HandyJSON协议，HandyJSON就能自行以各个属性的属性名为Key，从JSON串中解析值。HandyJSON目前依赖于从Swift Runtime源码中推断的内存规则，任何变动我们将随时跟进。
- [RxSwift](https://github.com/ReactiveX/RxSwift): 响应式编程三方库。这里主要处理网络请求时的各种回调和异步线程。

最终实现效果：
```
let provider = RxMoyaProvider<ApiManager>()
provider                                      //moya网络请求的manager
    .request(.getNewsList)                    //各种请求以枚举的形式调用
    .mapModel(listModel.self)                 //JOSN->Model
    .subscribe(onNext: { (model) in
        print(model)                          //请求数据回调，处理数据
    })
    .addDisposableTo(dispose)                 //资源回收
```
API枚举：
```
enum ApiManager {
    case getLaunchImg
    case getNewsList
    case getMoreNews(String)
    case getThemeList
    case getThemeDesc(Int)
    case getNewsDesc(Int)
}
```
由于Moya没有支持HandyJSON扩展，这里我自己实现了此扩展：
```
extension ObservableType where E == Response {
    public func mapModel<T: HandyJSON>(_ type: T.Type) -> Observable<T> {
        return flatMap { response -> Observable<T> in
            return Observable.just(response.mapModel(T.self))
        }
    }
}

extension Response {
    func mapModel<T: HandyJSON>(_ type: T.Type) -> T {
        let jsonString = String.init(data: data, encoding: .utf8)
        return JSONDeserializer<T>.deserializeFrom(json: jsonString)!
    }
}
```
只要Model遵循HandyJSON协议，就能很优雅的快速实现JSON->Model，包括嵌套解析：
```
struct listModel: HandyJSON {
    var date: String?
    var stories: [storyModel]?
    var top_stories: [storyModel]?
}

struct storyModel: HandyJSON {
    var ga_prefix: String?
    var id: Int?
    var images: [String]? //list_stories
    var title: String?
    var type: Int?
    var image: String? //top_stories
    var multipic = false
}
```
可以说，这是迄今为止我最满意的网络请求封装，以后都可以愉快处理请求啦😁


####数据呈现

数据请求处理好了，就该绑定视图显示出来了，这里就是RxSwift的拿手好戏了。下面我们先看最简单的展现：

```
    let provider = RxMoyaProvider<ApiManager>()
    let dispose = DisposeBag()
    let themeArr = Variable([ThemeModel]())
        
        //请求数据
        provider
            .request(.getThemeList)
            .mapModel(ThemeResponseModel.self)
            .subscribe(onNext: { (model) in
                self.themeArr.value = model.others!
            })
            .addDisposableTo(dispose)
        
        //绑定视图
        themeArr
            .asObservable()
            .bindTo(tableView.rx.items(cellIdentifier: "ThemeTableViewCell", cellType: ThemeTableViewCell.self)) {
                row, model, cell in
                cell.name.text = model.name
                cell.homeIcon.isHidden = row == 0 ? false : true
                cell.nameLeft.constant = row == 0 ? 50 : 15
        }
            .addDisposableTo(dispose)
      
       //响应视图   
        tableView.rx
            .modelSelected(ThemeModel.self)
            .subscribe(onNext: { (model) in
                self.showView = false
                self.showThemeVC(model)
            })
            .addDisposableTo(dispose)
```
这样简单的几行代码就完成网络请求数据展现以及用户响应一系列流程，什么代理，扩展都不用写了，减少了一半以上的代码，是不是看着就觉得爽炸了！我们再看看复杂一点的，分组tableview：
```
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, storyModel>>()
        let dispose = DisposeBag()

        dataSource.configureCell = { (dataSource, tv, indexPath, model) in
            let cell = tv.dequeueReusableCell(withIdentifier: "ListTableViewCell") as! ListTableViewCell
            cell.title.text = model.title
            cell.img.kf.setImage(with: URL.init(string: (model.images?.first)!))
            cell.morepicImg.isHidden = !model.multipic
            return cell
        }
        
        dataArr
            .asObservable()
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(dispose)
        
        tableView.rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
                self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
                let detailVc = DetailViewController()
                detailVc.id = model.id!
                self.navigationController?.pushViewController(detailVc, animated: true)
            })
            .addDisposableTo(dispose)
```
其实也很简单，就是需要绑定SectionModel，当然你也可以自定义SectionModel来分组展示，上面的代码都在项目筛选出来的，具体实现可以看文末项目链接。

###项目难点

####1. 菜单栏与主页面的切换



![menuShow.gif](https://github.com/kLike/ZhiHu-RxSwift/blob/master/ZhiHu%2BRxSwift/menuShow.gif)

由于导航栏一开始用的原生的（其实应该自定义，因为后面涉及到很多导航栏问题），所以左右平移的时候要把导航栏一起移动，所以遇到了一点问题，后来查找相关资料后解决了此问题：

```
    func showMenu() {
        let view = UIApplication.shared.keyWindow?.subviews.first
        let menuView = UIApplication.shared.keyWindow?.subviews.last
        UIApplication.shared.keyWindow?.bringSubview(toFront: (UIApplication.shared.keyWindow?.subviews[1])!)
        UIView.animate(withDuration: 0.5, animations: { 
            view?.transform = CGAffineTransform.init(translationX: 225, y: 0)
            menuView?.transform = (view?.transform)!
        })
    }
    
    func dismissMenu() {
        let view = UIApplication.shared.keyWindow?.subviews.first
        let menuView = UIApplication.shared.keyWindow?.subviews.last
        UIApplication.shared.keyWindow?.bringSubview(toFront: (UIApplication.shared.keyWindow?.subviews[1])!)
        UIView.animate(withDuration: 0.5, animations: {
            view?.transform = CGAffineTransform.init(translationX: 0, y: 0)
            menuView?.transform = (view?.transform)!
        })
    }
```
菜单栏的显示和隐藏需要配合手势，研究官方知乎日报App后，发现存在轻扫和拖拽滑动两个手势，相对应UIPanGestureRecognizer和UISwipeGestureRecognizer，当把这两个视图分别加在视图上的时候，只会响应一个手势，后来设置UIGestureRecognizerDelegate后避免了这个问题：
```
extension HomeViewController: UIGestureRecognizerDelegate {
    //是否允许手势识别器同时识别两个手势
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
```
本以为就此解决了问题，但是实际操作起来，手机很难区分这个两个手势，经常会搞错，本来想拖拽滑动结果系统识别为了轻扫手势，体验效果很差，那怎么办呢？后来终于找到一种可行方案：**只在视图上添加UIPanGestureRecognizer，以手指操作时间来区分是轻扫还是拖拽滑动**
```
    func panGesture(pan: UIPanGestureRecognizer) {
        let xoff = pan.translation(in: view).x
        if pan.state == .began {
            beganDate = Date()
        }
        if pan.state == .ended {
            endDate = Date()
            //区分是轻扫还是滑动
            if endDate! < beganDate! + 150000000.nanoseconds {
                if xoff > 0 {
                    showView = true
                } else {
                    showView = false
                }
                return
            }
        }
        //滑动范围以及滑动结束后需要show还是dismiss
        if (0 < xoff && xoff <= 225 && !showView) || (0 > xoff && xoff >= -225 && showView) {
            if pan.translation(in: view).x > 0 {
                moveMenu(pan.translation(in: view).x)
            } else {
                moveMenu(225 + pan.translation(in: view).x)
            }
            if pan.state == .ended {
                if showView {
                    if pan.translation(in: view).x < -175 {
                        showView = false
                    } else {
                        showView = true
                    }
                } else {
                    if pan.translation(in: view).x > 50 {
                        showView = true
                    } else {
                        showView = false
                    }
                }
            }
        }
    }
```
菜单栏与主页面的切换中还有一个不好处理的点，当选中菜单栏某个主题后，要推出一个主题日报列表，与首页不同属于一个UINavigationController，那怎么从一个UINavigationController到另一个UINavigationController呢？试了好几种方式来切换，始终达不到官方效果，忙碌了一天，最后灵光一现（也可能是我太蠢😫）平常不是都用UITabBarController来切换UINavigationController？！真的好简单，隐藏掉tabbar就好，几句代码就完美解决了这个场景切换问题：
```
    func showThemeVC(_ model: ThemeModel) {
        if model.id == nil {
            bindtoNav?.selectedIndex = 0
        } else {
            bindtoNav?.selectedIndex = 1
        }
    }
```
如果你有更好的切换方法请联系我，愿意请你喝咖啡😭

####2. 文章的快速切换

![newsChange.gif](https://github.com/kLike/ZhiHu-RxSwift/blob/master/ZhiHu%2BRxSwift/newsChange.gif)

文章详情是用UIWebView加载html数据来展现的，这里我自定义class DetailWebView: UIWebView，以便于两个文章详情的切换，用于显示文章详情的DetailViewController包含两个DetailWebView，一个webview用于展示当前页面，另一个previousWeb放在屏幕外准备随时切换文章，当发生切换文章时，动画呈现previousWeb，并在后续移除在屏幕外webview，把previousWeb作为新的webview，同时生成新的previousWeb
```
    //切换文章详情
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= -60 {
            if previousId > 0 {
                previousWeb.frame = CGRect.init(x: 0, y: -screenH, width: screenW, height: screenH)
                UIView.animate(withDuration: 0.3, animations: {
                    self.webview.transform = CGAffineTransform.init(translationX: 0, y: screenH)
                    self.previousWeb.transform = CGAffineTransform.init(translationX: 0, y: screenH)
                }, completion: { (state) in
                    if state { self.changeWebview(self.previousId) }
                })
            }
        }
        if scrollView.contentOffset.y - 50 + screenH >= scrollView.contentSize.height {
            if nextId > 0 {
                previousWeb.frame = CGRect.init(x: 0, y: screenH, width: screenW, height: screenH)
                UIView.animate(withDuration: 0.3, animations: {
                    self.previousWeb.transform = CGAffineTransform.init(translationX: 0, y: -screenH)
                    self.webview.transform = CGAffineTransform.init(translationX: 0, y: -screenH)
                }, completion: { (state) in
                    if state { self.changeWebview(self.nextId) }
                })
            }
        }
    }

    //切换之后后续处理
    func changeWebview(_ showID: Int) {
        webview.removeFromSuperview()
        previousWeb.scrollView.delegate = self
        previousWeb.delegate = self
        webview = previousWeb
        id = showID
        setUI()
        previousWeb = DetailWebView.init(frame: CGRect.init(x: 0, y: -screenH, width: screenW, height: screenH))
        view.addSubview(previousWeb)
        scrollViewDidScroll(webview.scrollView)
    }
```

####3.首页刷新
Swift版的刷新控件三方还没找比较好的，一度打算自己封装一个，但是一直拖着，😫以后应该会写。
知乎日报的刷新控件与一般放在tableview上不同，它应该是放在导航栏上面，配合tableview来实现刷新，这也是前面为什么说导航栏要自定义的原因之一，因为已经用了原生的导航栏，只好巧妙（偷懒）加在了view上，其实这个刷新就是一个画圆圈的过程，下面看看自定义的RefreshView:
```
class RefreshView: UIView {

    let circleLayer = CAShapeLayer()

    let indicatorView = UIActivityIndicatorView().then {
        $0.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
    }
    
    fileprivate var refreshing = false
    fileprivate var endRef = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        creatCircleLayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleLayer.position = CGPoint(x: frame.width/2, y: frame.height/2)
        indicatorView.center = CGPoint(x: frame.width/2, y: frame.height/2)
    }
    
    func creatCircleLayer() {
        circleLayer.path = UIBezierPath(arcCenter: CGPoint(x: 8, y: 8),
                               radius: 8,
                               startAngle: CGFloat(M_PI_2),
                               endAngle: CGFloat(M_PI_2 + 2*M_PI),
                               clockwise: true).cgPath
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeStart = 0.0
        circleLayer.strokeEnd = 0.0
        circleLayer.lineWidth = 1.0
        circleLayer.lineCap = kCALineCapRound
        circleLayer.bounds = CGRect(x: 0, y: 0, width: 16, height: 16)
        circleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension RefreshView {
    //向下拖拽视图准备刷新的过程会响应
    func pullToRefresh(progress: CGFloat) {
        circleLayer.strokeEnd = progress
    }
    //开始刷新
    func beginRefresh(begin: @escaping () -> Void) {
        if refreshing {
            //防止刷新未结束又开始请求刷新
            return
        }
        refreshing = true
        circleLayer.removeFromSuperlayer()
        addSubview(indicatorView)
        indicatorView.startAnimating()
        begin()
    }
    //结束刷新
    func endRefresh() {
        refreshing = false
        indicatorView.stopAnimating()
        indicatorView.removeFromSuperview()
    }
    //重制刷新控件
    func resetLayer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.creatCircleLayer()
        }
    }
    
}
```
###注意事项
- 项目中关于时间的处理用的是 [SwiftDate](https://github.com/malcommac/SwiftDate)
- .then 语法用的是 [Then](https://github.com/devxoul/Then)，小而妙，很喜欢

###总结
小生才疏学浅，未有编程天赋，难免有许多谬误纰漏之处，各位看官当看且看，若有任何问题都可以提出，愿接受各种批评建议。要是觉得这篇文章稍有用处，可以给个star，十分感激。
